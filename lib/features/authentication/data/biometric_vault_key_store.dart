import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/utilities/bytes.dart';

class BiometricVaultKeyStore {
  BiometricVaultKeyStore({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuthentication,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _keyName = 'vault_key_v1';
  static const _androidOptions = AndroidOptions.biometric(
    enforceBiometrics: true,
    storageNamespace: 'localvault_biometric_key',
    biometricPromptTitle: 'Unlock LocalVault',
    biometricPromptSubtitle: 'Authenticate to unlock the vault key',
  );
  static const _iosOptions = IOSOptions(
    accountName: 'localvault_biometric_key',
    accessibility: KeychainAccessibility.passcode,
    synchronizable: false,
    accessControlFlags: [AccessControlFlag.userPresence],
    useSecureEnclave: true,
  );

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication;

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveVaultKey(List<int> vaultKey) async {
    if (!await canUseBiometrics()) {
      throw const SecureStorageUnavailableException();
    }
    try {
      await _secureStorage.write(
        key: _keyName,
        value: bytesToBase64(vaultKey),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (_) {
      throw const SecureStorageUnavailableException();
    }
  }

  Future<List<int>?> readVaultKey() async {
    try {
      final raw = await _secureStorage.read(
        key: _keyName,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      return raw == null ? null : base64ToBytes(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() {
    return _secureStorage.delete(
      key: _keyName,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
