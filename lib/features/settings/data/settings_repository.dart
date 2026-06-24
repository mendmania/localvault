import '../../../core/database/app_database.dart';
import '../domain/settings_models.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  Future<VaultUserSettings> load() async {
    final rows = await _database.select(_database.vaultSettings).get();
    final values = {for (final row in rows) row.key: row.value};
    return VaultUserSettings(
      autoLockTimeout: AutoLockTimeout.values.firstWhere(
        (value) => value.name == values['autoLockTimeout'],
        orElse: () => AutoLockTimeout.minute1,
      ),
      clipboardTimeout: Duration(
        seconds: int.tryParse(values['clipboardTimeoutSeconds'] ?? '') ?? 30,
      ),
      preferredUnitSystem: PreferredUnitSystem.values.firstWhere(
        (value) => value.name == values['preferredUnitSystem'],
        orElse: () => PreferredUnitSystem.metric,
      ),
      themeSelection: AppThemeSelection.values.firstWhere(
        (value) => value.name == values['themeSelection'],
        orElse: () => AppThemeSelection.system,
      ),
      biometricUnlockEnabled: values['biometricUnlockEnabled'] == 'true',
    );
  }

  Future<void> save(VaultUserSettings settings) async {
    await _database.transaction(() async {
      await _write('autoLockTimeout', settings.autoLockTimeout.name);
      await _write(
        'clipboardTimeoutSeconds',
        settings.clipboardTimeout.inSeconds.toString(),
      );
      await _write('preferredUnitSystem', settings.preferredUnitSystem.name);
      await _write('themeSelection', settings.themeSelection.name);
      await _write(
        'biometricUnlockEnabled',
        settings.biometricUnlockEnabled.toString(),
      );
    });
  }

  Future<void> _write(String key, String value) {
    return _database
        .into(_database.vaultSettings)
        .insertOnConflictUpdate(
          VaultSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }
}
