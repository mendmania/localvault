import 'dart:convert';
import 'dart:io';

import 'crypto_metadata.dart';

abstract interface class VaultMetadataStore {
  Future<VaultCryptoMetadata?> read();
  Future<void> write(VaultCryptoMetadata metadata);
  Future<void> delete();
}

class FileVaultMetadataStore implements VaultMetadataStore {
  const FileVaultMetadataStore(this.file);

  final File file;

  @override
  Future<VaultCryptoMetadata?> read() async {
    if (!await file.exists()) {
      return null;
    }
    final raw = await file.readAsString();
    return VaultCryptoMetadata.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  }

  @override
  Future<void> write(VaultCryptoMetadata metadata) async {
    await file.parent.create(recursive: true);
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(metadata.toJson()), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  @override
  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class MemoryVaultMetadataStore implements VaultMetadataStore {
  VaultCryptoMetadata? _metadata;

  @override
  Future<void> delete() async {
    _metadata = null;
  }

  @override
  Future<VaultCryptoMetadata?> read() async => _metadata;

  @override
  Future<void> write(VaultCryptoMetadata metadata) async {
    _metadata = metadata;
  }
}
