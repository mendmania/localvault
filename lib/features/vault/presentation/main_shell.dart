import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../app/theme/app_theme.dart';
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
    final pages = [
      const VaultDashboard(),
      const PeopleListPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton(
              tooltip: 'Quick add',
              onPressed: () => _showQuickAdd(context),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Future<void> _showQuickAdd(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Credential'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditCredentialPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_rounded),
                  title: const Text('Person'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditPersonPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.straighten_rounded),
                  title: const Text('Measurement'),
                  onTap: () async {
                    Navigator.pop(context);
                    final people = await ref
                        .read(peopleRepositoryProvider)
                        .all();
                    if (!context.mounted) {
                      return;
                    }
                    if (people.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Add a person before adding measurements.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditMeasurementPage(personId: people.first.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
