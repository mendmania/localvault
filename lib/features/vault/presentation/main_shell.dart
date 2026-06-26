import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/adaptive_controls.dart'
    hide IconBadgeTone, TonedIconBadge;
import '../../../core/widgets/vault_ui.dart';
import '../../people/presentation/people_pages.dart';
import '../../settings/presentation/settings_page.dart';
import 'credential_pages.dart';
import 'security_page.dart';
import 'vault_search_page.dart';
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
      const VaultSearchPage(),
      const SecurityPage(),
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
                      onLock: () =>
                          ref.read(vaultControllerProvider.notifier).lock(),
                    ),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
                    ),
                  ],
                )
              : IndexedStack(index: _index, children: pages),
          bottomNavigationBar: wide
              ? null
              : _GlassTabBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                ),
          floatingActionButton: _index == 4
              ? null
              : GlassSurface(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(4),
                  child: IconButton.filled(
                    tooltip: 'Quick add',
                    onPressed: () => _showQuickAdd(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
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

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassSurface(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            borderRadius: AppRadii.nav,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _TabButton(
                      destination: _destinations[i],
                      selected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primaryContainer.withValues(alpha: 0.92)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    destination.icon,
                    size: 22,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
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
    required this.onLock,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: GlassSurface(
          borderRadius: AppRadii.nav,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: SizedBox(
            width: 92,
            child: Column(
              children: [
                const SizedBox(height: 4),
                for (var i = 0; i < _destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _RailButton(
                      destination: _destinations[i],
                      selected: selectedIndex == i,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Lock vault',
                  onPressed: onLock,
                  icon: const Icon(Icons.lock_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Icon(
                destination.icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const _destinations = [
  _ShellDestination(label: 'Vault', icon: Icons.password_rounded),
  _ShellDestination(label: 'People', icon: Icons.people_alt_rounded),
  _ShellDestination(label: 'Search', icon: Icons.manage_search_rounded),
  _ShellDestination(label: 'Security', icon: Icons.shield_rounded),
  _ShellDestination(label: 'Settings', icon: Icons.settings_rounded),
];
