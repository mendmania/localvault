import '../../../core/database/app_database.dart';
import '../../measurements/domain/measurement_models.dart';

class LocalSearchResult {
  const LocalSearchResult({
    required this.label,
    required this.kind,
    this.subtitle,
    this.credential,
    this.person,
    this.measurement,
  });

  final String label;
  final String kind;
  final String? subtitle;
  final Credential? credential;
  final Person? person;
  final Measurement? measurement;
}

List<LocalSearchResult> searchVault({
  required String query,
  required List<Credential> credentials,
  required List<Person> people,
  required List<Measurement> measurements,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }
  final personById = {for (final person in people) person.id: person};
  final results = <LocalSearchResult>[];
  for (final credential in credentials) {
    final owner = credential.personId == null
        ? null
        : personById[credential.personId!];
    if (_containsAny(normalized, [
      credential.title,
      credential.loginIdentifier,
      credential.website,
      credential.notes,
      owner?.displayName,
    ])) {
      results.add(
        LocalSearchResult(
          label: credential.title,
          kind: 'Credential',
          subtitle: owner?.displayName ?? credential.loginIdentifier,
          credential: credential,
        ),
      );
    }
  }
  for (final person in people) {
    if (_containsAny(normalized, [
      person.displayName,
      person.relationshipLabel,
      person.notes,
    ])) {
      results.add(
        LocalSearchResult(
          label: person.displayName,
          kind: 'Person',
          subtitle: person.relationshipLabel,
          person: person,
        ),
      );
    }
  }
  for (final measurement in measurements) {
    final owner = personById[measurement.personId];
    final template = templateFor(measurement.type);
    if (_containsAny(normalized, [
      measurement.customLabel ?? template.label,
      owner?.displayName,
      measurement.sizeLabel,
      measurement.sizeSystem,
      measurement.side,
      measurement.notes,
    ])) {
      results.add(
        LocalSearchResult(
          label: measurement.customLabel ?? template.label,
          kind: 'Measurement',
          subtitle: owner?.displayName,
          measurement: measurement,
        ),
      );
    }
  }
  return results;
}

bool _containsAny(String query, Iterable<String?> values) {
  for (final value in values) {
    if (value != null && value.toLowerCase().contains(query)) {
      return true;
    }
  }
  return false;
}
