import 'package:flutter_test/flutter_test.dart';
import 'package:localvault/core/crypto/crypto_metadata.dart';
import 'package:localvault/core/crypto/vault_crypto.dart';
import 'package:localvault/core/errors/app_exceptions.dart';

void main() {
  test('Argon2id metadata serializes and restores', () {
    final params = Argon2idParams.mobileV1;
    final restored = Argon2idParams.fromJson(params.toJson());

    expect(restored.memoryKiB, 19 * 1024);
    expect(restored.iterations, 2);
    expect(restored.parallelism, 1);
    expect(restored.outputLength, 32);
  });

  test(
    'AES-GCM vault key wraps, unwraps, rejects wrong password, and rewraps',
    () async {
      final crypto = VaultCrypto();
      final created = await crypto.createEnvelope(
        'correct horse battery staple',
      );

      final unwrapped = await crypto.unwrapVaultKey(
        metadata: created.metadata,
        masterPassword: 'correct horse battery staple',
      );
      expect(unwrapped, created.vaultKey);

      expect(
        () => crypto.unwrapVaultKey(
          metadata: created.metadata,
          masterPassword: 'wrong password value',
        ),
        throwsA(isA<InvalidMasterPasswordException>()),
      );

      final rewrapped = await crypto.wrapVaultKey(
        vaultKey: unwrapped,
        masterPassword: 'new correct horse battery staple',
      );
      final afterRewrap = await crypto.unwrapVaultKey(
        metadata: rewrapped,
        masterPassword: 'new correct horse battery staple',
      );
      expect(afterRewrap, created.vaultKey);
    },
  );
}
