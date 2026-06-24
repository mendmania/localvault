import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/core/database/app_database.dart';
import 'package:localvault/features/vault/domain/search.dart';

void main() {
  test('searches allowed fields and never password contents only', () {
    final now = DateTime.utc(2026);
    final person = Person(
      id: 'p1',
      displayName: 'Parent',
      relationshipLabel: 'Mom',
      notes: null,
      createdAt: now,
      updatedAt: now,
    );
    final credential = Credential(
      id: 'c1',
      personId: 'p1',
      title: 'Insurance portal',
      loginIdentifier: 'parent@example.com',
      secret: 'UniqueSecretNotSearchable',
      website: 'https://insurance.invalid',
      notes: 'Renewal only',
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );

    expect(
      searchVault(
        query: 'insurance',
        credentials: [credential],
        people: [person],
        measurements: const [],
      ),
      hasLength(1),
    );

    expect(
      searchVault(
        query: 'UniqueSecretNotSearchable',
        credentials: [credential],
        people: [person],
        measurements: const [],
      ),
      isEmpty,
    );
  });
}
