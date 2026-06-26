import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/adaptive_controls.dart'
    hide IconBadgeTone, TonedIconBadge;
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../people/presentation/people_pages.dart';
import '../domain/search.dart';
import 'credential_pages.dart';

class VaultSearchPage extends ConsumerStatefulWidget {
  const VaultSearchPage({super.key});

  @override
  ConsumerState<VaultSearchPage> createState() => _VaultSearchPageState();
}

class _VaultSearchPageState extends ConsumerState<VaultSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _query = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final credentialRepository = ref.watch(credentialRepositoryProvider);
    final peopleRepository = ref.watch(peopleRepositoryProvider);
    final measurementRepository = ref.watch(measurementRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            tooltip: 'Lock vault',
            onPressed: () => ref.read(vaultControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Credential>>(
        stream: credentialRepository.watchAll(),
        builder: (context, credentialSnapshot) {
          final credentials = credentialSnapshot.data ?? const <Credential>[];
          return FutureBuilder<(List<Person>, List<Measurement>)>(
            future:
                Future.wait([
                  peopleRepository.all(),
                  measurementRepository.all(),
                ]).then(
                  (values) => (
                    values[0] as List<Person>,
                    values[1] as List<Measurement>,
                  ),
                ),
            builder: (context, snapshot) {
              final people = snapshot.data?.$1 ?? const <Person>[];
              final measurements = snapshot.data?.$2 ?? const <Measurement>[];
              final results = searchVault(
                query: _query,
                credentials: credentials,
                people: people,
                measurements: measurements,
              );
              final commands = _commandsForQuery(_query);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                children: [
                  GlassSurface(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(8),
                    child: AdaptiveSearchField(
                      controller: _controller,
                      onChanged: _onChanged,
                      hintText: 'Search records and actions',
                      onClear: () {
                        _debounce?.cancel();
                        setState(() => _query = '');
                      },
                    ),
                  ),
                  if (_query.isEmpty) ...[
                    VaultSection(
                      title: 'Actions',
                      child: Column(children: _commandRows(_allCommands)),
                    ),
                    VaultSection(
                      title: 'Browse',
                      child: Column(
                        children: [
                          VaultListRow(
                            icon: Icons.key_rounded,
                            title: 'Credentials',
                            subtitle: '${credentials.length} saved',
                          ),
                          VaultListRow(
                            icon: Icons.people_alt_rounded,
                            title: 'People',
                            subtitle: '${people.length} profiles',
                            tone: IconBadgeTone.secondary,
                          ),
                          VaultListRow(
                            icon: Icons.straighten_rounded,
                            title: 'Measurements',
                            subtitle: '${measurements.length} entries',
                            tone: IconBadgeTone.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (commands.isNotEmpty)
                      VaultSection(
                        title: 'Actions',
                        child: Column(children: _commandRows(commands)),
                      ),
                    if (results.isEmpty && commands.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 56),
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message: 'Passwords are never searched.',
                        ),
                      )
                    else if (results.isNotEmpty)
                      VaultSection(
                        title: 'Records',
                        child: Column(
                          children: [
                            for (final result in results)
                              VaultListRow(
                                icon: switch (result.kind) {
                                  'Credential' => Icons.key_rounded,
                                  'Person' => Icons.person_rounded,
                                  _ => Icons.straighten_rounded,
                                },
                                title: result.label,
                                subtitle: [
                                  result.kind,
                                  if (result.subtitle != null) result.subtitle!,
                                ].join(' • '),
                                tone: switch (result.kind) {
                                  'Person' => IconBadgeTone.secondary,
                                  'Measurement' => IconBadgeTone.tertiary,
                                  _ => IconBadgeTone.primary,
                                },
                                onTap: () => _openResult(context, result),
                              ),
                          ],
                        ),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _commandRows(List<_SearchCommand> commands) {
    return [
      for (final command in commands)
        VaultListRow(
          icon: command.icon,
          title: command.label,
          subtitle: command.subtitle,
          tone: command.tone,
          onTap: () => command.run(context, ref),
        ),
    ];
  }

  List<_SearchCommand> _commandsForQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    return _allCommands
        .where(
          (command) =>
              command.label.toLowerCase().contains(normalized) ||
              command.keywords.any((word) => word.contains(normalized)),
        )
        .toList();
  }

  List<_SearchCommand> get _allCommands => [
    _SearchCommand(
      label: 'Add credential',
      subtitle: 'Create a login or private secret',
      icon: Icons.key_rounded,
      keywords: const ['new', 'password', 'secret', 'login'],
      run: (context, ref) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AddEditCredentialPage())),
    ),
    _SearchCommand(
      label: 'Add person',
      subtitle: 'Create a profile',
      icon: Icons.person_add_alt_rounded,
      tone: IconBadgeTone.secondary,
      keywords: const ['new', 'profile', 'people'],
      run: (context, ref) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AddEditPersonPage())),
    ),
    _SearchCommand(
      label: 'Add measurement',
      subtitle: 'Save a size or body measurement',
      icon: Icons.straighten_rounded,
      tone: IconBadgeTone.tertiary,
      keywords: const ['new', 'size', 'height', 'shoe'],
      run: _addMeasurement,
    ),
    _SearchCommand(
      label: 'Lock vault',
      subtitle: 'Return to the unlock screen',
      icon: Icons.lock_rounded,
      keywords: const ['secure', 'close'],
      run: (context, ref) => ref.read(vaultControllerProvider.notifier).lock(),
    ),
  ];

  Future<void> _addMeasurement(BuildContext context, WidgetRef ref) async {
    final people = await ref.read(peopleRepositoryProvider).all();
    if (!context.mounted) {
      return;
    }
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a person before measurements.')),
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

  void _openResult(BuildContext context, LocalSearchResult result) {
    final credential = result.credential;
    if (credential != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CredentialDetailPage(credentialId: credential.id),
        ),
      );
      return;
    }
    final person = result.person;
    if (person != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonProfilePage(personId: person.id),
        ),
      );
      return;
    }
    final measurement = result.measurement;
    if (measurement != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditMeasurementPage(
            personId: measurement.personId,
            measurement: measurement,
          ),
        ),
      );
    }
  }
}

class _SearchCommand {
  const _SearchCommand({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.keywords,
    required this.run,
    this.tone = IconBadgeTone.primary,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;
  final IconBadgeTone tone;
  final FutureOr<void> Function(BuildContext context, WidgetRef ref) run;
}
