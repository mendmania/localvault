import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/app/lifecycle/vault_controller.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/core/security/platform_security.dart';
import 'package:localvault/features/settings/domain/settings_models.dart';

class _FakePlatformSecurity extends PlatformSecurity {
  @override
  Future<void> enableSensitiveScreenProtection() async {}

  @override
  Future<void> disableSensitiveScreenProtection() async {}

  @override
  Future<void> excludeFromBackup(Iterable<String> paths) async {}

  @override
  Future<Uint8List?> pickBackupFile() async => null;
}

void main() {
  test('locks on resume when background timeout elapsed', () async {
    var now = DateTime.utc(2026, 6, 25, 12);
    final database = AppDatabase(NativeDatabase.memory(logStatements: false));
    final controller = VaultController(
      platformSecurity: _FakePlatformSecurity(),
      now: () => now,
      initialState: VaultState(
        status: VaultStatus.unlocked,
        database: database,
        hasVault: true,
        settings: const VaultUserSettings(
          autoLockTimeout: AutoLockTimeout.seconds30,
        ),
      ),
    );

    await controller.appMovedToBackground();
    now = now.add(const Duration(seconds: 31));
    await controller.appResumed();

    expect(controller.state.status, VaultStatus.locked);
    expect(controller.state.database, isNull);
  });

  test('stays unlocked on resume before background timeout elapses', () async {
    var now = DateTime.utc(2026, 6, 25, 12);
    final database = AppDatabase(NativeDatabase.memory(logStatements: false));
    addTearDown(database.close);
    final controller = VaultController(
      platformSecurity: _FakePlatformSecurity(),
      now: () => now,
      initialState: VaultState(
        status: VaultStatus.unlocked,
        database: database,
        hasVault: true,
        settings: const VaultUserSettings(
          autoLockTimeout: AutoLockTimeout.seconds30,
        ),
      ),
    );

    await controller.appMovedToBackground();
    now = now.add(const Duration(seconds: 10));
    await controller.appResumed();

    expect(controller.state.status, VaultStatus.unlocked);
    expect(controller.state.database, same(database));
  });
}
