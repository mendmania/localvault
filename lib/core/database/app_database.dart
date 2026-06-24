import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('Person')
class People extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get relationshipLabel => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Credentials extends Table {
  TextColumn get id => text()();
  TextColumn get personId =>
      text().nullable().references(People, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text()();
  TextColumn get loginIdentifier => text().nullable()();
  TextColumn get secret => text()();
  TextColumn get website => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Measurements extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(People, #id)();
  TextColumn get type => text()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get valueKind => text()();
  IntColumn get canonicalValueMmX100 => integer().nullable()();
  TextColumn get sizeLabel => text().nullable()();
  TextColumn get sizeSystem => text().nullable()();
  TextColumn get side => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get measuredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VaultSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [People, Credentials, Measurements, VaultSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
