import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/adaptive_controls.dart';
import '../../people/presentation/people_pages.dart';
import '../../settings/presentation/settings_page.dart';
import 'credential_pages.dart';
import 'vault_dashboard.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultControllerProvider);
    if (!vaultState.isUnlocked) {
      return const SizedBox.shrink();
    }
    final pages = [
      const VaultDashboard(),
      const PeopleListPage(),
      const SettingsPage(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        return Scaffold(
          body: wide
              ? Row(
                  children: [
                    _FloatingNavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                    ),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ],
                )
              : IndexedStack(index: _index, children: pages),
          bottomNavigationBar: wide
              ? null
              : _FloatingNavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                ),
          floatingActionButton: _index == 2
              ? null
              : FloatingActionButton(
                  tooltip: 'Quick add',
                  onPressed: () => _showQuickAdd(context),
                  child: const Icon(Icons.add_rounded),
                ),
        );
      },
    );
  }

  Future<void> _showQuickAdd(BuildContext context) async {
    final action = await showAdaptiveChoiceSheet<_QuickAddAction>(
      context: context,
      title: 'Quick add',
      options: const [
        AdaptiveOption(
          value: _QuickAddAction.credential,
          label: 'Credential',
          icon: Icons.key_rounded,
        ),
        AdaptiveOption(
          value: _QuickAddAction.person,
          label: 'Person',
          icon: Icons.person_add_alt_rounded,
        ),
        AdaptiveOption(
          value: _QuickAddAction.measurement,
          label: 'Measurement',
          icon: Icons.straighten_rounded,
        ),
      ],
    );
    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case _QuickAddAction.credential:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditCredentialPage()),
        );
      case _QuickAddAction.person:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddEditPersonPage()));
      case _QuickAddAction.measurement:
        final people = await ref.read(peopleRepositoryProvider).all();
        if (!context.mounted) {
          return;
        }
        if (people.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add a person before adding measurements.'),
            ),
          );
          return;
        }
        final personId = await showAdaptiveChoiceSheet<String>(
          context: context,
          title: 'Add measurement for',
          options: people
              .map(
                (person) => AdaptiveOption(
                  value: person.id,
                  label: person.displayName,
                  icon: Icons.person_rounded,
                ),
              )
              .toList(),
        );
        if (!context.mounted || personId == null) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditMeasurementPage(personId: personId),
          ),
        );
    }
  }
}

enum _QuickAddAction { credential, person, measurement }

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          widthFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.16),
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.password_rounded),
                    label: 'Vault',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_alt_rounded),
                    label: 'People',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavigationRail extends StatelessWidget {
  const _FloatingNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Material(
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.password_rounded),
                label: Text('Vault'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_rounded),
                label: Text('People'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
