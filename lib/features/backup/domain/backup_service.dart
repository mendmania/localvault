import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../../core/crypto/crypto_metadata.dart';
import '../../../core/crypto/vault_crypto.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utilities/bytes.dart';

const backupMagic = 'LOCALVAULT_BACKUP';
const backupFormatVersion = 1;

class BackupService {
  BackupService({VaultCrypto? crypto, AesGcm? aesGcm})
    : _crypto = crypto ?? VaultCrypto(),
      _aesGcm = aesGcm ?? AesGcm.with256bits();

  final VaultCrypto _crypto;
  final AesGcm _aesGcm;

  Future<List<int>> createEncryptedBackup({
    required AppDatabase database,
    required String backupPassword,
  }) async {
    final payload = await _snapshot(database);
    final salt = secureRandomBytes(16);
    final params = Argon2idParams.mobileV1;
    final derived = _crypto.deriveKey(
      password: backupPassword,
      salt: salt,
      params: params,
    );
    try {
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(jsonEncode(payload)),
        secretKey: SecretKey(derived.key),
        nonce: secureRandomBytes(12),
      );
      final backup = {
        'magic': backupMagic,
        'formatVersion': backupFormatVersion,
        'kdfAlgorithm': argon2idAlgorithm,
        'kdfParams': params.toJson(),
        'salt': bytesToBase64(salt),
        'algorithm': aes256GcmAlgorithm,
        'nonce': bytesToBase64(secretBox.nonce),
        'ciphertext': bytesToBase64(secretBox.cipherText),
        'authenticationTag': bytesToBase64(secretBox.mac.bytes),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      return utf8.encode(jsonEncode(backup));
    } finally {
      clearBytes(derived.key);
    }
  }

  Future<void> restoreEncryptedBackup({
    required AppDatabase database,
    required List<int> backupBytes,
    required String backupPassword,
  }) async {
    final backup = jsonDecode(utf8.decode(backupBytes)) as Map<String, Object?>;
    if (backup['magic'] != backupMagic) {
      throw const UnsupportedBackupVersionException();
    }
    if (backup['formatVersion'] != backupFormatVersion) {
      throw const UnsupportedBackupVersionException();
    }
    final params = Argon2idParams.fromJson(
      backup['kdfParams'] as Map<String, Object?>,
    );
    final derived = _crypto.deriveKey(
      password: backupPassword,
      salt: base64ToBytes(backup['salt'] as String),
      params: params,
    );
    try {
      final secretBox = SecretBox(
        base64ToBytes(backup['ciphertext'] as String),
        nonce: base64ToBytes(backup['nonce'] as String),
        mac: Mac(base64ToBytes(backup['authenticationTag'] as String)),
      );
      final clear = await _aesGcm.decrypt(
        secretBox,
        secretKey: SecretKey(derived.key),
      );
      final payload = jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
      _validatePayload(payload);
      await _restoreSnapshot(database, payload);
    } on SecretBoxAuthenticationError {
      throw const BackupAuthenticationException();
    } on FormatException {
      throw const UnsupportedBackupVersionException();
    } finally {
      clearBytes(derived.key);
    }
  }

  Future<Map<String, Object?>> _snapshot(AppDatabase database) async {
    final people = await database.select(database.people).get();
    final credentials = await database.select(database.credentials).get();
    final measurements = await database.select(database.measurements).get();
    final settings = await database.select(database.vaultSettings).get();
    return {
      'version': 1,
      'people': people.map(_personToJson).toList(),
      'credentials': credentials.map(_credentialToJson).toList(),
      'measurements': measurements.map(_measurementToJson).toList(),
      'settings': settings.map(_settingToJson).toList(),
    };
  }

  Future<void> _restoreSnapshot(
    AppDatabase database,
    Map<String, Object?> payload,
  ) async {
    await database.transaction(() async {
      await database.delete(database.measurements).go();
      await database.delete(database.credentials).go();
      await database.delete(database.people).go();
      await database.delete(database.vaultSettings).go();
      for (final row in payload['people']! as List<Object?>) {
        await database
            .into(database.people)
            .insert(_personFromJson(row as Map<String, Object?>));
      }
      for (final row in payload['credentials']! as List<Object?>) {
        await database
            .into(database.credentials)
            .insert(_credentialFromJson(row as Map<String, Object?>));
      }
      for (final row in payload['measurements']! as List<Object?>) {
        await database
            .into(database.measurements)
            .insert(_measurementFromJson(row as Map<String, Object?>));
      }
      for (final row in payload['settings']! as List<Object?>) {
        await database
            .into(database.vaultSettings)
            .insert(_settingFromJson(row as Map<String, Object?>));
      }
    });
  }

  void _validatePayload(Map<String, Object?> payload) {
    if (payload['version'] != 1 ||
        payload['people'] is! List ||
        payload['credentials'] is! List ||
        payload['measurements'] is! List ||
        payload['settings'] is! List) {
      throw const UnsupportedBackupVersionException();
    }
  }

  Map<String, Object?> _personToJson(Person person) => {
    'id': person.id,
    'displayName': person.displayName,
    'relationshipLabel': person.relationshipLabel,
    'notes': person.notes,
    'createdAt': person.createdAt.toUtc().toIso8601String(),
    'updatedAt': person.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> _credentialToJson(Credential credential) => {
    'id': credential.id,
    'personId': credential.personId,
    'title': credential.title,
    'loginIdentifier': credential.loginIdentifier,
    'secret': credential.secret,
    'website': credential.website,
    'notes': credential.notes,
    'isFavorite': credential.isFavorite,
    'createdAt': credential.createdAt.toUtc().toIso8601String(),
    'updatedAt': credential.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> _measurementToJson(Measurement measurement) => {
    'id': measurement.id,
    'personId': measurement.personId,
    'type': measurement.type,
    'customLabel': measurement.customLabel,
    'valueKind': measurement.valueKind,
    'canonicalValueMmX100': measurement.canonicalValueMmX100,
    'sizeLabel': measurement.sizeLabel,
    'sizeSystem': measurement.sizeSystem,
    'side': measurement.side,
    'notes': measurement.notes,
    'measuredAt': measurement.measuredAt?.toUtc().toIso8601String(),
    'createdAt': measurement.createdAt.toUtc().toIso8601String(),
    'updatedAt': measurement.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> _settingToJson(VaultSetting setting) => {
    'key': setting.key,
    'value': setting.value,
    'updatedAt': setting.updatedAt.toUtc().toIso8601String(),
  };

  PeopleCompanion _personFromJson(Map<String, Object?> json) {
    return PeopleCompanion.insert(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      relationshipLabel: Value(json['relationshipLabel'] as String?),
      notes: Value(json['notes'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  CredentialsCompanion _credentialFromJson(Map<String, Object?> json) {
    return CredentialsCompanion.insert(
      id: json['id'] as String,
      personId: Value(json['personId'] as String?),
      title: json['title'] as String,
      loginIdentifier: Value(json['loginIdentifier'] as String?),
      secret: json['secret'] as String,
      website: Value(json['website'] as String?),
      notes: Value(json['notes'] as String?),
      isFavorite: Value(json['isFavorite'] as bool),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  MeasurementsCompanion _measurementFromJson(Map<String, Object?> json) {
    return MeasurementsCompanion.insert(
      id: json['id'] as String,
      personId: json['personId'] as String,
      type: json['type'] as String,
      customLabel: Value(json['customLabel'] as String?),
      valueKind: json['valueKind'] as String,
      canonicalValueMmX100: Value(json['canonicalValueMmX100'] as int?),
      sizeLabel: Value(json['sizeLabel'] as String?),
      sizeSystem: Value(json['sizeSystem'] as String?),
      side: json['side'] as String,
      notes: Value(json['notes'] as String?),
      measuredAt: Value(
        json['measuredAt'] == null
            ? null
            : DateTime.parse(json['measuredAt'] as String),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  VaultSettingsCompanion _settingFromJson(Map<String, Object?> json) {
    return VaultSettingsCompanion.insert(
      key: json['key'] as String,
      value: json['value'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
