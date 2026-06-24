import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/core/crypto/vault_crypto.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/core/database/encrypted_database.dart';
import 'package:localvault/core/errors/app_exceptions.dart';
import 'package:localvault/features/vault/data/vault_repositories.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(logStatements: false));
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'credential, person, and measurement CRUD with safe person deletion',
    () async {
      final people = PeopleRepository(database);
      final credentials = CredentialRepository(database);
      final measurements = MeasurementRepository(database);

      final personId = await people.create(
        displayName: 'Parent',
        relationshipLabel: 'Dad',
      );
      final credentialId = await credentials.create(
        title: 'Utility portal',
        secret: 'not-a-real-password',
        personId: personId,
      );
      final measurementId = await measurements.create(
        personId: personId,
        type: 'height',
        valueKind: 'linearLength',
        canonicalValueMmX100: 180000,
        side: 'notApplicable',
      );

      expect(await people.byId(personId), isNotNull);
      expect(await credentials.byId(credentialId), isNotNull);
      expect(await measurements.byId(measurementId), isNotNull);

      final impact = await people.deletionImpact(personId);
      expect(impact.credentialCount, 1);
      expect(impact.measurementCount, 1);

      await people.deletePerson(
        id: personId,
        deleteMeasurements: true,
        unassignCredentials: true,
      );
      final credential = await credentials.byId(credentialId);
      expect(credential?.personId, isNull);
      expect(await people.byId(personId), isNull);
      expect(await measurements.byId(measurementId), isNull);
    },
  );

  test(
    'encrypted raw database does not contain marker and rejects wrong key',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'localvault_db_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final file = File('${tempDir.path}/vault.db');
      final crypto = VaultCrypto();
      final envelope = await crypto.createEnvelope(
        'correct horse battery staple',
      );
      final marker = 'marker-${DateTime.now().microsecondsSinceEpoch}';

      final encryptedDb = EncryptedDatabaseFactory(
        databaseFile: file,
      ).open(envelope.vaultKey);
      await CredentialRepository(
        encryptedDb,
      ).create(title: 'Marker', secret: marker);
      await encryptedDb.close();

      final raw = await file.readAsBytes();
      expect(utf8.decode(raw, allowMalformed: true).contains(marker), isFalse);

      await expectLater(
        crypto.unwrapVaultKey(
          metadata: envelope.metadata,
          masterPassword: 'wrong password value',
        ),
        throwsA(isA<InvalidMasterPasswordException>()),
      );

      final correctKey = await crypto.unwrapVaultKey(
        metadata: envelope.metadata,
        masterPassword: 'correct horse battery staple',
      );
      final reopened = EncryptedDatabaseFactory(
        databaseFile: file,
      ).open(correctKey);
      addTearDown(reopened.close);
      final restored = await CredentialRepository(reopened).all();
      expect(restored.single.secret, marker);
    },
  );
}
