import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VaultPaths {
  const VaultPaths._(this.supportDirectory);

  final Directory supportDirectory;

  static Future<VaultPaths> load() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return VaultPaths._(directory);
  }

  File get databaseFile => File(p.join(supportDirectory.path, 'vault.db'));
  File get metadataFile =>
      File(p.join(supportDirectory.path, 'vault_metadata.json'));
  Directory get backupDirectory =>
      Directory(p.join(supportDirectory.path, 'backups'));

  Future<void> deleteVaultFiles() async {
    for (final file in [
      databaseFile,
      File('${databaseFile.path}-wal'),
      File('${databaseFile.path}-shm'),
      metadataFile,
    ]) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
