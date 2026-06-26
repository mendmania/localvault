import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lifecycle/vault_controller.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/adaptive_controls.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../people/presentation/people_pages.dart';
import '../domain/search.dart';
import 'credential_pages.dart';

class VaultDashboard extends ConsumerStatefulWidget {
  const VaultDashboard({super.key});

  @override
  ConsumerState<VaultDashboard> createState() => _VaultDashboardState();
}

class _VaultDashboardState extends ConsumerState<VaultDashboard> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  String? _personFilter;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
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
        title: const Text('Vault'),
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
              final displayedCredentials = credentials.where((credential) {
                return _personFilter == null ||
                    credential.personId == _personFilter;
              }).toList();
              final favoriteCredentials = displayedCredentials
                  .where((credential) => credential.isFavorite)
                  .toList();
              final otherCredentials = displayedCredentials
                  .where((credential) => !credential.isFavorite)
                  .toList();
              final searchResults = searchVault(
                query: _query,
                credentials: credentials,
                people: people,
                measurements: measurements,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  AdaptiveSearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hintText: 'Search vault',
                    onClear: () {
                      _debounce?.cancel();
                      setState(() => _query = '');
                    },
                  ),
                  if (people.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PersonFilterChips(
                      people: people,
                      selectedPersonId: _personFilter,
                      onChanged: (value) =>
                          setState(() => _personFilter = value),
                    ),
                  ],
                  if (_query.isNotEmpty)
                    _SearchResults(results: searchResults)
                  else if (credentials.isEmpty)
                    EmptyState(
                      icon: Icons.key_off_rounded,
                      title: 'No credentials yet',
                      message:
                          'Add occasional passwords and private notes that should stay on this device.',
                      action: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddEditCredentialPage(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add credential'),
                      ),
                    )
                  else if (displayedCredentials.isEmpty &&
                      _personFilter != null)
                    EmptyState(
                      icon: Icons.key_off_rounded,
                      title: 'No credentials for this person',
                      message:
                          'Add a credential that belongs to ${_personFor(people, _personFilter)?.displayName ?? 'this person'}.',
                      action: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditCredentialPage(
                              initialPersonId: _personFilter,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add credential'),
                      ),
                    )
                  else ...[
                    if (favoriteCredentials.isNotEmpty) ...[
                      const SectionHeader('Favorites'),
                      ...favoriteCredentials.map(
                        (credential) => _CredentialCard(
                          credential: credential,
                          person: _personFor(people, credential.personId),
                        ),
                      ),
                    ],
                    if (otherCredentials.isNotEmpty ||
                        favoriteCredentials.isEmpty) ...[
                      SectionHeader(
                        favoriteCredentials.isEmpty
                            ? 'Credentials'
                            : 'Other credentials',
                      ),
                      ...otherCredentials.map(
                        (credential) => _CredentialCard(
                          credential: credential,
                          person: _personFor(people, credential.personId),
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Person? _personFor(List<Person> people, String? id) {
    if (id == null) {
      return null;
    }
    for (final person in people) {
      if (person.id == id) {
        return person;
      }
    }
    return null;
  }
}

class _PersonFilterChips extends StatelessWidget {
  const _PersonFilterChips({
    required this.people,
    required this.selectedPersonId,
    required this.onChanged,
  });

  final List<Person> people;
  final String? selectedPersonId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selectedPersonId == null,
              onSelected: (_) => onChanged(null),
              label: const Text('All'),
            ),
          ),
          ...people.map(
            (person) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selectedPersonId == person.id,
                onSelected: (_) => onChanged(person.id),
                label: Text(person.displayName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});

  final List<LocalSearchResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Passwords are never searched or suggested.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Search results'),
        ...results.map(
          (result) => Card(
            child: ListTile(
              leading: TonedIconBadge(
                icon: switch (result.kind) {
                  'Credential' => Icons.key_rounded,
                  'Person' => Icons.person_rounded,
                  _ => Icons.straighten_rounded,
                },
                tone: switch (result.kind) {
                  'Person' => IconBadgeTone.secondary,
                  'Measurement' => IconBadgeTone.tertiary,
                  _ => IconBadgeTone.primary,
                },
              ),
              title: Text(result.label),
              subtitle: Text(
                [
                  result.kind,
                  if (result.subtitle != null) result.subtitle!,
                ].join(' • '),
              ),
              onTap: () => _openResult(context, result),
            ),
          ),
        ),
      ],
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

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.credential, this.person});

  final Credential credential;
  final Person? person;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Card(
        child: ListTile(
          leading: Hero(
            tag: 'credential-icon-${credential.id}',
            child: TonedIconBadge(
              icon: credential.isFavorite
                  ? Icons.star_rounded
                  : Icons.key_rounded,
              tone: credential.isFavorite
                  ? IconBadgeTone.tertiary
                  : IconBadgeTone.primary,
            ),
          ),
          title: Text(credential.title),
          subtitle: Text(
            [
              if (credential.loginIdentifier != null)
                credential.loginIdentifier!,
              if (person != null) person!.displayName,
              'Password hidden',
            ].join(' • '),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CredentialDetailPage(credentialId: credential.id),
            ),
          ),
        ),
      ),
    );
  }
}
