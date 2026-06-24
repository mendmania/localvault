import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/crypto/vault_crypto.dart';
import '../../core/crypto/vault_metadata_store.dart';
import '../../core/database/app_database.dart';
import '../../core/database/encrypted_database.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/security/clipboard_service.dart';
import '../../core/security/platform_security.dart';
import '../../core/utilities/bytes.dart';
import '../../features/authentication/data/biometric_vault_key_store.dart';
import '../../features/backup/domain/backup_service.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/domain/settings_models.dart';
import '../../features/vault/data/vault_repositories.dart';
import 'vault_paths.dart';

enum VaultStatus {
  initializing,
  needsOnboarding,
  locked,
  unlocking,
  unlocked,
  busy,
  error,
}

class VaultState {
  const VaultState({
    required this.status,
    this.database,
    this.settings = const VaultUserSettings(),
    this.errorMessage,
    this.hasVault = false,
    this.biometricAvailable = false,
    this.needsBiometricChoice = false,
  });

  final VaultStatus status;
  final AppDatabase? database;
  final VaultUserSettings settings;
  final String? errorMessage;
  final bool hasVault;
  final bool biometricAvailable;
  final bool needsBiometricChoice;

  bool get isUnlocked => status == VaultStatus.unlocked && database != null;

  VaultState copyWith({
    VaultStatus? status,
    AppDatabase? database,
    bool clearDatabase = false,
    VaultUserSettings? settings,
    String? errorMessage,
    bool clearError = false,
    bool? hasVault,
    bool? biometricAvailable,
    bool? needsBiometricChoice,
  }) {
    return VaultState(
      status: status ?? this.status,
      database: clearDatabase ? null : database ?? this.database,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasVault: hasVault ?? this.hasVault,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      needsBiometricChoice: needsBiometricChoice ?? this.needsBiometricChoice,
    );
  }
}

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultState>((ref) {
      final controller = VaultController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final credentialRepositoryProvider = Provider<CredentialRepository>((ref) {
  final database = ref.watch(vaultControllerProvider).database;
  if (database == null) {
    throw const VaultNotUnlockedException();
  }
  return CredentialRepository(database);
});

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final database = ref.watch(vaultControllerProvider).database;
  if (database == null) {
    throw const VaultNotUnlockedException();
  }
  return PeopleRepository(database);
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  final database = ref.watch(vaultControllerProvider).database;
  if (database == null) {
    throw const VaultNotUnlockedException();
  }
  return MeasurementRepository(database);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final database = ref.watch(vaultControllerProvider).database;
  if (database == null) {
    throw const VaultNotUnlockedException();
  }
  return SettingsRepository(database);
});

final backupServiceProvider = Provider((ref) => BackupService());
final clipboardServiceProvider = Provider((ref) {
  final service = ClipboardService();
  ref.onDispose(service.dispose);
  return service;
});

class VaultController extends StateNotifier<VaultState> {
  VaultController({
    VaultCrypto? crypto,
    BiometricVaultKeyStore? biometricVaultKeyStore,
    PlatformSecurity? platformSecurity,
    VaultState? initialState,
  }) : _crypto = crypto ?? VaultCrypto(),
       _biometricVaultKeyStore =
           biometricVaultKeyStore ?? BiometricVaultKeyStore(),
       _platformSecurity = platformSecurity ?? PlatformSecurity(),
       super(
         initialState ?? const VaultState(status: VaultStatus.initializing),
       );

  final VaultCrypto _crypto;
  final BiometricVaultKeyStore _biometricVaultKeyStore;
  final PlatformSecurity _platformSecurity;
  VaultPaths? _paths;
  VaultMetadataStore? _metadataStore;
  Uint8List? _vaultKey;
  Timer? _autoLockTimer;

  Future<void> initialize() async {
    if (state.status != VaultStatus.initializing) {
      return;
    }
    try {
      final paths = await VaultPaths.load();
      _paths = paths;
      _metadataStore = FileVaultMetadataStore(paths.metadataFile);
      await _platformSecurity.excludeFromBackup([
        paths.databaseFile.path,
        '${paths.databaseFile.path}-wal',
        '${paths.databaseFile.path}-shm',
        paths.metadataFile.path,
      ]);
      final metadata = await _metadataStore!.read();
      final biometricAvailable =
          metadata != null && await _biometricVaultKeyStore.canUseBiometrics();
      state = state.copyWith(
        status: metadata == null
            ? VaultStatus.needsOnboarding
            : VaultStatus.locked,
        hasVault: metadata != null,
        biometricAvailable: biometricAvailable,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: VaultStatus.error,
        errorMessage: 'LocalVault could not initialize local storage.',
      );
    }
  }

  Future<void> createVault(String masterPassword) async {
    final store = _requireStore();
    if (await store.read() != null) {
      throw const VaultAlreadyExistsException();
    }
    state = state.copyWith(status: VaultStatus.busy, clearError: true);
    final envelope = await _crypto.createEnvelope(masterPassword);
    try {
      await store.write(envelope.metadata);
      await _openWithVaultKey(envelope.vaultKey);
      await _ensureDefaultSettings();
      state = state.copyWith(hasVault: true, needsBiometricChoice: true);
    } catch (_) {
      clearBytes(envelope.vaultKey);
      rethrow;
    }
  }

  Future<void> unlockWithPassword(String masterPassword) async {
    final store = _requireStore();
    final metadata = await store.read();
    if (metadata == null) {
      state = state.copyWith(status: VaultStatus.needsOnboarding);
      return;
    }
    state = state.copyWith(status: VaultStatus.unlocking, clearError: true);
    try {
      final vaultKey = await _crypto.unwrapVaultKey(
        metadata: metadata,
        masterPassword: masterPassword,
      );
      await _openWithVaultKey(vaultKey);
    } on LocalVaultException catch (error) {
      state = state.copyWith(
        status: VaultStatus.locked,
        errorMessage: error.safeMessage,
      );
    }
  }

  Future<void> unlockWithBiometrics() async {
    state = state.copyWith(status: VaultStatus.unlocking, clearError: true);
    final vaultKey = await _biometricVaultKeyStore.readVaultKey();
    if (vaultKey == null) {
      state = state.copyWith(
        status: VaultStatus.locked,
        errorMessage:
            'Biometric unlock is unavailable. Use the master password.',
      );
      return;
    }
    await _openWithVaultKey(Uint8List.fromList(vaultKey));
  }

  Future<void> enableBiometricUnlock() async {
    final key = _vaultKey;
    if (key == null || state.database == null) {
      throw const VaultNotUnlockedException();
    }
    await _biometricVaultKeyStore.saveVaultKey(key);
    final settings = state.settings.copyWith(biometricUnlockEnabled: true);
    await SettingsRepository(state.database!).save(settings);
    state = state.copyWith(
      settings: settings,
      biometricAvailable: true,
      clearError: true,
    );
  }

  Future<void> disableBiometricUnlock() async {
    await _biometricVaultKeyStore.clear();
    final database = state.database;
    if (database != null) {
      final settings = state.settings.copyWith(biometricUnlockEnabled: false);
      await SettingsRepository(database).save(settings);
      state = state.copyWith(settings: settings);
    }
  }

  void markBiometricChoiceComplete() {
    state = state.copyWith(needsBiometricChoice: false);
  }

  Future<void> changeMasterPassword(String newMasterPassword) async {
    final key = _vaultKey;
    if (key == null) {
      throw const VaultNotUnlockedException();
    }
    final metadata = await _crypto.wrapVaultKey(
      vaultKey: key,
      masterPassword: newMasterPassword,
    );
    await _requireStore().write(metadata);
  }

  Future<void> updateSettings(VaultUserSettings settings) async {
    final database = state.database;
    if (database == null) {
      throw const VaultNotUnlockedException();
    }
    await SettingsRepository(database).save(settings);
    state = state.copyWith(settings: settings);
    _scheduleAutoLock();
  }

  Future<void> exportBackup({
    required String backupPassword,
    required BackupService backupService,
  }) async {
    final database = state.database;
    final paths = _paths;
    if (database == null || paths == null) {
      throw const VaultNotUnlockedException();
    }
    final backupBytes = await backupService.createEncryptedBackup(
      database: database,
      backupPassword: backupPassword,
    );
    await paths.backupDirectory.create(recursive: true);
    final file = File(
      p.join(
        paths.backupDirectory.path,
        'localvault-${DateTime.now().toUtc().millisecondsSinceEpoch}.lvbackup',
      ),
    );
    await file.writeAsBytes(backupBytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'LocalVault encrypted backup',
        text: 'Store this encrypted LocalVault backup somewhere safe.',
      ),
    );
  }

  Future<void> importBackup({
    required String backupPassword,
    required BackupService backupService,
  }) async {
    final database = state.database;
    if (database == null) {
      throw const VaultNotUnlockedException();
    }
    final bytes = await _platformSecurity.pickBackupFile();
    if (bytes == null) {
      return;
    }
    await backupService.restoreEncryptedBackup(
      database: database,
      backupBytes: bytes,
      backupPassword: backupPassword,
    );
  }

  Future<void> noteUserActivity() async {
    if (state.isUnlocked) {
      _scheduleAutoLock();
    }
  }

  Future<void> appMovedToBackground() async {
    final timeout = state.settings.autoLockTimeout;
    if (timeout == AutoLockTimeout.immediately) {
      await lock();
      return;
    }
    _scheduleAutoLock();
  }

  Future<void> lock() async {
    _autoLockTimer?.cancel();
    final database = state.database;
    state = state.copyWith(status: VaultStatus.locked, clearDatabase: true);
    await database?.close();
    await _platformSecurity.disableSensitiveScreenProtection();
    clearBytes(_vaultKey);
    _vaultKey = null;
  }

  Future<void> deleteVault() async {
    await lock();
    await _metadataStore?.delete();
    await _biometricVaultKeyStore.clear();
    await _paths?.deleteVaultFiles();
    state = const VaultState(status: VaultStatus.needsOnboarding);
  }

  Future<void> _openWithVaultKey(Uint8List vaultKey) async {
    final paths = _paths;
    if (paths == null) {
      throw const VaultCorruptedException();
    }
    final previous = state.database;
    await previous?.close();
    clearBytes(_vaultKey);
    final database = EncryptedDatabaseFactory(
      databaseFile: paths.databaseFile,
    ).open(vaultKey);
    _vaultKey = vaultKey;
    final settings = await SettingsRepository(database).load();
    await _platformSecurity.enableSensitiveScreenProtection();
    state = state.copyWith(
      status: VaultStatus.unlocked,
      database: database,
      settings: settings,
      hasVault: true,
      clearError: true,
    );
    _scheduleAutoLock();
  }

  Future<void> _ensureDefaultSettings() async {
    final database = state.database;
    if (database == null) {
      return;
    }
    final repository = SettingsRepository(database);
    final settings = await repository.load();
    await repository.save(settings);
    state = state.copyWith(settings: settings);
  }

  VaultMetadataStore _requireStore() {
    final store = _metadataStore;
    if (store == null) {
      throw const VaultCorruptedException();
    }
    return store;
  }

  void _scheduleAutoLock() {
    _autoLockTimer?.cancel();
    final timeout = state.settings.autoLockTimeout.duration;
    if (timeout == Duration.zero) {
      unawaited(lock());
      return;
    }
    _autoLockTimer = Timer(timeout, () {
      unawaited(lock());
    });
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    clearBytes(_vaultKey);
    state.database?.close();
    super.dispose();
  }
}
