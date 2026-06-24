import '../utilities/bytes.dart';

const currentCryptoFormatVersion = 1;
const argon2idAlgorithm = 'argon2id';
const aes256GcmAlgorithm = 'aes-256-gcm';

class Argon2idParams {
  const Argon2idParams({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.version,
    required this.outputLength,
  });

  static const mobileV1 = Argon2idParams(
    memoryKiB: 19 * 1024,
    iterations: 2,
    parallelism: 1,
    version: 0x13,
    outputLength: 32,
  );

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int version;
  final int outputLength;

  Map<String, Object?> toJson() => {
    'memoryKiB': memoryKiB,
    'iterations': iterations,
    'parallelism': parallelism,
    'version': version,
    'outputLength': outputLength,
  };

  factory Argon2idParams.fromJson(Map<String, Object?> json) {
    return Argon2idParams(
      memoryKiB: json['memoryKiB'] as int,
      iterations: json['iterations'] as int,
      parallelism: json['parallelism'] as int,
      version: json['version'] as int,
      outputLength: json['outputLength'] as int,
    );
  }
}

class VaultCryptoMetadata {
  const VaultCryptoMetadata({
    required this.formatVersion,
    required this.kdfAlgorithm,
    required this.kdfParams,
    required this.salt,
    required this.wrapAlgorithm,
    required this.nonce,
    required this.wrappedVaultKey,
    required this.authenticationTag,
    required this.kdfBenchmarkMillis,
    required this.createdAt,
    required this.updatedAt,
  });

  final int formatVersion;
  final String kdfAlgorithm;
  final Argon2idParams kdfParams;
  final List<int> salt;
  final String wrapAlgorithm;
  final List<int> nonce;
  final List<int> wrappedVaultKey;
  final List<int> authenticationTag;
  final int kdfBenchmarkMillis;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'kdfAlgorithm': kdfAlgorithm,
    'kdfParams': kdfParams.toJson(),
    'salt': bytesToBase64(salt),
    'wrapAlgorithm': wrapAlgorithm,
    'nonce': bytesToBase64(nonce),
    'wrappedVaultKey': bytesToBase64(wrappedVaultKey),
    'authenticationTag': bytesToBase64(authenticationTag),
    'kdfBenchmarkMillis': kdfBenchmarkMillis,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  VaultCryptoMetadata copyWith({
    Argon2idParams? kdfParams,
    List<int>? salt,
    List<int>? nonce,
    List<int>? wrappedVaultKey,
    List<int>? authenticationTag,
    int? kdfBenchmarkMillis,
    DateTime? updatedAt,
  }) {
    return VaultCryptoMetadata(
      formatVersion: formatVersion,
      kdfAlgorithm: kdfAlgorithm,
      kdfParams: kdfParams ?? this.kdfParams,
      salt: salt ?? this.salt,
      wrapAlgorithm: wrapAlgorithm,
      nonce: nonce ?? this.nonce,
      wrappedVaultKey: wrappedVaultKey ?? this.wrappedVaultKey,
      authenticationTag: authenticationTag ?? this.authenticationTag,
      kdfBenchmarkMillis: kdfBenchmarkMillis ?? this.kdfBenchmarkMillis,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory VaultCryptoMetadata.fromJson(Map<String, Object?> json) {
    return VaultCryptoMetadata(
      formatVersion: json['formatVersion'] as int,
      kdfAlgorithm: json['kdfAlgorithm'] as String,
      kdfParams: Argon2idParams.fromJson(
        json['kdfParams'] as Map<String, Object?>,
      ),
      salt: base64ToBytes(json['salt'] as String),
      wrapAlgorithm: json['wrapAlgorithm'] as String,
      nonce: base64ToBytes(json['nonce'] as String),
      wrappedVaultKey: base64ToBytes(json['wrappedVaultKey'] as String),
      authenticationTag: base64ToBytes(json['authenticationTag'] as String),
      kdfBenchmarkMillis: json['kdfBenchmarkMillis'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
