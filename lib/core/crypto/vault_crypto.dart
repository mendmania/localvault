import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:cryptography/cryptography.dart';

import '../errors/app_exceptions.dart';
import '../utilities/bytes.dart';
import 'crypto_metadata.dart';

class DerivedKeyResult {
  const DerivedKeyResult({required this.key, required this.elapsedMillis});

  final Uint8List key;
  final int elapsedMillis;
}

class CreatedVaultEnvelope {
  const CreatedVaultEnvelope({required this.metadata, required this.vaultKey});

  final VaultCryptoMetadata metadata;
  final Uint8List vaultKey;
}

class VaultCrypto {
  VaultCrypto({AesGcm? aesGcm}) : _aesGcm = aesGcm ?? AesGcm.with256bits();

  final AesGcm _aesGcm;

  Future<CreatedVaultEnvelope> createEnvelope(String masterPassword) async {
    final vaultKey = secureRandomBytes(32);
    final metadata = await wrapVaultKey(
      vaultKey: vaultKey,
      masterPassword: masterPassword,
      createdAt: DateTime.now().toUtc(),
    );
    return CreatedVaultEnvelope(metadata: metadata, vaultKey: vaultKey);
  }

  Future<VaultCryptoMetadata> wrapVaultKey({
    required List<int> vaultKey,
    required String masterPassword,
    DateTime? createdAt,
  }) async {
    final salt = secureRandomBytes(16);
    final params = Argon2idParams.mobileV1;
    final derived = deriveKey(
      password: masterPassword,
      salt: salt,
      params: params,
    );
    try {
      final nonce = secureRandomBytes(12);
      final secretBox = await _aesGcm.encrypt(
        vaultKey,
        secretKey: SecretKey(derived.key),
        nonce: nonce,
      );
      final now = DateTime.now().toUtc();
      return VaultCryptoMetadata(
        formatVersion: currentCryptoFormatVersion,
        kdfAlgorithm: argon2idAlgorithm,
        kdfParams: params,
        salt: salt,
        wrapAlgorithm: aes256GcmAlgorithm,
        nonce: secretBox.nonce,
        wrappedVaultKey: secretBox.cipherText,
        authenticationTag: secretBox.mac.bytes,
        kdfBenchmarkMillis: derived.elapsedMillis,
        createdAt: createdAt ?? now,
        updatedAt: now,
      );
    } finally {
      clearBytes(derived.key);
    }
  }

  Future<Uint8List> unwrapVaultKey({
    required VaultCryptoMetadata metadata,
    required String masterPassword,
  }) async {
    if (metadata.formatVersion != currentCryptoFormatVersion ||
        metadata.kdfAlgorithm != argon2idAlgorithm ||
        metadata.wrapAlgorithm != aes256GcmAlgorithm) {
      throw const VaultCorruptedException();
    }
    final derived = deriveKey(
      password: masterPassword,
      salt: metadata.salt,
      params: metadata.kdfParams,
    );
    try {
      final secretBox = SecretBox(
        metadata.wrappedVaultKey,
        nonce: metadata.nonce,
        mac: Mac(metadata.authenticationTag),
      );
      final clearKey = await _aesGcm.decrypt(
        secretBox,
        secretKey: SecretKey(derived.key),
      );
      return Uint8List.fromList(clearKey);
    } on SecretBoxAuthenticationError {
      throw const InvalidMasterPasswordException();
    } catch (_) {
      throw const InvalidMasterPasswordException();
    } finally {
      clearBytes(derived.key);
    }
  }

  DerivedKeyResult deriveKey({
    required String password,
    required List<int> salt,
    required Argon2idParams params,
  }) {
    final stopwatch = Stopwatch()..start();
    final argon2 = Argon2BytesGenerator()
      ..init(
        Argon2Parameters(
          Argon2Parameters.ARGON2_id,
          Uint8List.fromList(salt),
          iterations: params.iterations,
          memory: params.memoryKiB,
          lanes: params.parallelism,
          version: params.version,
        ),
      );
    final passwordBytes = CharToByteConverter.UTF8.convert(password);
    final result = Uint8List(params.outputLength);
    try {
      argon2.generateBytes(passwordBytes, result, 0, result.length);
    } finally {
      clearBytes(passwordBytes);
      stopwatch.stop();
    }
    return DerivedKeyResult(
      key: result,
      elapsedMillis: stopwatch.elapsedMilliseconds,
    );
  }
}
