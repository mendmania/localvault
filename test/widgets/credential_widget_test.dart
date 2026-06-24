import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/app/lifecycle/vault_controller.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/features/vault/data/vault_repositories.dart';
import 'package:localvault/features/vault/presentation/credential_pages.dart';

void main() {
  late AppDatabase database;
  late VaultController controller;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(logStatements: false));
    controller = VaultController(
      initialState: VaultState(
        status: VaultStatus.unlocked,
        database: database,
        hasVault: true,
      ),
    );
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [vaultControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('password remains masked initially and reveal shows it', (
    tester,
  ) async {
    final id = await CredentialRepository(
      database,
    ).create(title: 'Insurance', secret: 'widget-secret-value');

    await tester.pumpWidget(wrap(CredentialDetailPage(credentialId: id)));
    await tester.pumpAndSettle();

    expect(find.text('••••••••••••'), findsOneWidget);
    expect(find.text('widget-secret-value'), findsNothing);

    await tester.tap(find.text('Reveal'));
    await tester.pumpAndSettle();

    expect(find.text('widget-secret-value'), findsOneWidget);
  });

  testWidgets('required-field validation is shown for credential form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const AddEditCredentialPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsAtLeastNWidgets(2));
  });
}
