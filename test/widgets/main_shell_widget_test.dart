import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/app/lifecycle/vault_controller.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/features/vault/data/vault_repositories.dart';
import 'package:localvault/features/vault/presentation/main_shell.dart';

void main() {
  late AppDatabase database;
  late VaultController controller;
  late List<Person> people;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(logStatements: false));
    people = const [];
    controller = VaultController(
      initialState: VaultState(
        status: VaultStatus.unlocked,
        database: database,
        hasVault: true,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        vaultControllerProvider.overrideWith((ref) => controller),
        credentialRepositoryProvider.overrideWith(
          (ref) => _FakeCredentialRepository(database),
        ),
        peopleRepositoryProvider.overrideWith(
          (ref) => _FakePeopleRepository(database, people),
        ),
        measurementRepositoryProvider.overrideWith(
          (ref) => _FakeMeasurementRepository(database),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  Future<void> disposeShell(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('compact shell uses glass tabs and hides quick add on settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsWidgets);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Security'), findsWidgets);
    expect(find.byTooltip('Quick add'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Biometric unlock'), findsOneWidget);
    expect(find.byTooltip('Quick add'), findsNothing);
    await disposeShell(tester);
  });

  testWidgets('wide shell uses navigation rail and switches tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsWidgets);
    expect(find.text('Security'), findsWidgets);

    await tester.tap(find.byIcon(Icons.people_alt_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('No people yet'), findsOneWidget);
    await disposeShell(tester);
  });

  testWidgets('quick add measurement requires a person', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quick add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Measurement'));
    await tester.pumpAndSettle();

    expect(
      find.text('Add a person before adding measurements.'),
      findsOneWidget,
    );
    await disposeShell(tester);
  });

  testWidgets('quick add measurement asks which person to use', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    people = [_person(id: 'p1', displayName: 'Ava')];

    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quick add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Measurement'));
    await tester.pumpAndSettle();

    expect(find.text('Add measurement for'), findsOneWidget);
    expect(find.text('Ava'), findsWidgets);

    await tester.tap(find.text('Ava').last);
    await tester.pumpAndSettle();

    expect(find.text('Add measurement'), findsOneWidget);
    await disposeShell(tester);
  });
}

Person _person({required String id, required String displayName}) {
  final now = DateTime.utc(2026, 6, 25);
  return Person(
    id: id,
    displayName: displayName,
    relationshipLabel: null,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCredentialRepository extends CredentialRepository {
  _FakeCredentialRepository(super.database);

  @override
  Stream<List<Credential>> watchAll() => Stream.value(const []);

  @override
  Future<List<Credential>> all() async => const [];
}

class _FakePeopleRepository extends PeopleRepository {
  _FakePeopleRepository(super.database, this._people);

  final List<Person> _people;

  @override
  Stream<List<Person>> watchAll() => Stream.value(_people);

  @override
  Future<List<Person>> all() async => _people;
}

class _FakeMeasurementRepository extends MeasurementRepository {
  _FakeMeasurementRepository(super.database);

  @override
  Future<List<Measurement>> all() async => const [];
}
