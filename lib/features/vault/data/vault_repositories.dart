import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

const _uuid = Uuid();

class CredentialRepository {
  CredentialRepository(this._database);

  final AppDatabase _database;

  Stream<List<Credential>> watchAll() {
    return (_database.select(_database.credentials)..orderBy([
          (table) => OrderingTerm.desc(table.isFavorite),
          (table) => OrderingTerm.desc(table.updatedAt),
        ]))
        .watch();
  }

  Future<List<Credential>> all() =>
      _database.select(_database.credentials).get();

  Future<List<Credential>> forPerson(String personId) {
    return (_database.select(
      _database.credentials,
    )..where((table) => table.personId.equals(personId))).get();
  }

  Future<Credential?> byId(String id) {
    return (_database.select(
      _database.credentials,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<String> create({
    required String title,
    required String secret,
    String? personId,
    String? loginIdentifier,
    String? website,
    String? notes,
    bool isFavorite = false,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _database
        .into(_database.credentials)
        .insert(
          CredentialsCompanion.insert(
            id: id,
            title: title.trim(),
            secret: secret,
            personId: Value(personId),
            loginIdentifier: Value(_blankToNull(loginIdentifier)),
            website: Value(_blankToNull(website)),
            notes: Value(_blankToNull(notes)),
            isFavorite: Value(isFavorite),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateCredential({
    required String id,
    required String title,
    required String secret,
    String? personId,
    String? loginIdentifier,
    String? website,
    String? notes,
    required bool isFavorite,
  }) {
    return (_database.update(
      _database.credentials,
    )..where((table) => table.id.equals(id))).write(
      CredentialsCompanion(
        title: Value(title.trim()),
        secret: Value(secret),
        personId: Value(personId),
        loginIdentifier: Value(_blankToNull(loginIdentifier)),
        website: Value(_blankToNull(website)),
        notes: Value(_blankToNull(notes)),
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_database.delete(
      _database.credentials,
    )..where((table) => table.id.equals(id))).go();
  }
}

class PeopleRepository {
  PeopleRepository(this._database);

  final AppDatabase _database;

  Stream<List<Person>> watchAll() {
    return (_database.select(
      _database.people,
    )..orderBy([(table) => OrderingTerm.asc(table.displayName)])).watch();
  }

  Future<List<Person>> all() => _database.select(_database.people).get();

  Future<Person?> byId(String id) {
    return (_database.select(
      _database.people,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<String> create({
    required String displayName,
    String? relationshipLabel,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _database
        .into(_database.people)
        .insert(
          PeopleCompanion.insert(
            id: id,
            displayName: displayName.trim(),
            relationshipLabel: Value(_blankToNull(relationshipLabel)),
            notes: Value(_blankToNull(notes)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updatePerson({
    required String id,
    required String displayName,
    String? relationshipLabel,
    String? notes,
  }) {
    return (_database.update(
      _database.people,
    )..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        displayName: Value(displayName.trim()),
        relationshipLabel: Value(_blankToNull(relationshipLabel)),
        notes: Value(_blankToNull(notes)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<PersonDeletionImpact> deletionImpact(String personId) async {
    final credentialCount =
        await (_database.select(_database.credentials)
              ..where((row) => row.personId.equals(personId)))
            .get()
            .then((rows) => rows.length);
    final measurementCount =
        await (_database.select(_database.measurements)
              ..where((row) => row.personId.equals(personId)))
            .get()
            .then((rows) => rows.length);
    return PersonDeletionImpact(
      credentialCount: credentialCount,
      measurementCount: measurementCount,
    );
  }

  Future<void> deletePerson({
    required String id,
    required bool deleteMeasurements,
    required bool unassignCredentials,
  }) {
    return _database.transaction(() async {
      if (unassignCredentials) {
        await (_database.update(
          _database.credentials,
        )..where((row) => row.personId.equals(id))).write(
          CredentialsCompanion(
            personId: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
      if (deleteMeasurements) {
        await (_database.delete(
          _database.measurements,
        )..where((row) => row.personId.equals(id))).go();
      }
      await (_database.delete(
        _database.people,
      )..where((row) => row.id.equals(id))).go();
    });
  }
}

class MeasurementRepository {
  MeasurementRepository(this._database);

  final AppDatabase _database;

  Stream<List<Measurement>> watchForPerson(String personId) {
    return (_database.select(_database.measurements)
          ..where((row) => row.personId.equals(personId))
          ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
        .watch();
  }

  Future<List<Measurement>> all() =>
      _database.select(_database.measurements).get();

  Future<Measurement?> byId(String id) {
    return (_database.select(
      _database.measurements,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<String> create({
    required String personId,
    required String type,
    String? customLabel,
    required String valueKind,
    int? canonicalValueMmX100,
    String? sizeLabel,
    String? sizeSystem,
    required String side,
    String? notes,
    DateTime? measuredAt,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _database
        .into(_database.measurements)
        .insert(
          MeasurementsCompanion.insert(
            id: id,
            personId: personId,
            type: type,
            customLabel: Value(_blankToNull(customLabel)),
            valueKind: valueKind,
            canonicalValueMmX100: Value(canonicalValueMmX100),
            sizeLabel: Value(_blankToNull(sizeLabel)),
            sizeSystem: Value(_blankToNull(sizeSystem)),
            side: side,
            notes: Value(_blankToNull(notes)),
            measuredAt: Value(measuredAt),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateMeasurement({
    required String id,
    required String type,
    String? customLabel,
    required String valueKind,
    int? canonicalValueMmX100,
    String? sizeLabel,
    String? sizeSystem,
    required String side,
    String? notes,
    DateTime? measuredAt,
  }) {
    return (_database.update(
      _database.measurements,
    )..where((row) => row.id.equals(id))).write(
      MeasurementsCompanion(
        type: Value(type),
        customLabel: Value(_blankToNull(customLabel)),
        valueKind: Value(valueKind),
        canonicalValueMmX100: Value(canonicalValueMmX100),
        sizeLabel: Value(_blankToNull(sizeLabel)),
        sizeSystem: Value(_blankToNull(sizeSystem)),
        side: Value(side),
        notes: Value(_blankToNull(notes)),
        measuredAt: Value(measuredAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_database.delete(
      _database.measurements,
    )..where((row) => row.id.equals(id))).go();
  }
}

class PersonDeletionImpact {
  const PersonDeletionImpact({
    required this.credentialCount,
    required this.measurementCount,
  });

  final int credentialCount;
  final int measurementCount;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
