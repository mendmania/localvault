import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/settings_models.dart';
import 'lifecycle/vault_controller.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class LocalVaultApp extends ConsumerWidget {
  const LocalVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vaultControllerProvider);
    return MaterialApp.router(
      title: 'My Pocket Memory',
      debugShowCheckedModeBanner: false,
      theme: buildLocalVaultTheme(Brightness.light),
      darkTheme: buildLocalVaultTheme(Brightness.dark),
      themeMode: switch (state.settings.themeSelection) {
        AppThemeSelection.system => ThemeMode.system,
        AppThemeSelection.light => ThemeMode.light,
        AppThemeSelection.dark => ThemeMode.dark,
      },
      routerConfig: appRouter,
    );
  }
}
