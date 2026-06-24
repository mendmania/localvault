import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/core/errors/app_exceptions.dart';
import 'package:localvault/features/backup/domain/backup_service.dart';
import 'package:localvault/features/vault/data/vault_repositories.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'backup encrypts, authenticates, restores, and rejects wrong password',
    () async {
      final source = AppDatabase(NativeDatabase.memory(logStatements: false));
      final target = AppDatabase(NativeDatabase.memory(logStatements: false));
      addTearDown(source.close);
      addTearDown(target.close);

      final personId = await PeopleRepository(
        source,
      ).create(displayName: 'Mom');
      await CredentialRepository(source).create(
        title: 'Insurance',
        secret: 'backup-marker-secret',
        personId: personId,
      );

      final service = BackupService();
      final backup = await service.createEncryptedBackup(
        database: source,
        backupPassword: 'backup password value',
      );
      expect(
        String.fromCharCodes(backup).contains('backup-marker-secret'),
        isFalse,
      );

      await expectLater(
        service.restoreEncryptedBackup(
          database: target,
          backupBytes: backup,
          backupPassword: 'wrong backup password',
        ),
        throwsA(isA<BackupAuthenticationException>()),
      );

      await service.restoreEncryptedBackup(
        database: target,
        backupBytes: backup,
        backupPassword: 'backup password value',
      );
      final restored = await CredentialRepository(target).all();
      expect(restored.single.secret, 'backup-marker-secret');
    },
  );

  test('backup version rejection', () async {
    final database = AppDatabase(NativeDatabase.memory(logStatements: false));
    addTearDown(database.close);
    final service = BackupService();

    await expectLater(
      service.restoreEncryptedBackup(
        database: database,
        backupBytes: '{}'.codeUnits,
        backupPassword: 'backup password value',
      ),
      throwsA(isA<UnsupportedBackupVersionException>()),
    );
  });
}
