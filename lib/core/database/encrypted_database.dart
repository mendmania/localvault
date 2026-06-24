import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../errors/app_exceptions.dart';
import '../utilities/bytes.dart';
import 'app_database.dart';

class EncryptedDatabaseFactory {
  const EncryptedDatabaseFactory({required this.databaseFile});

  final File databaseFile;

  AppDatabase open(Uint8List vaultKey) {
    final keyCopy = Uint8List.fromList(vaultKey);
    final executor = NativeDatabase.createInBackground(
      databaseFile,
      logStatements: false,
      setup: (database) {
        _setupEncryptedDatabase(database, keyCopy);
      },
    );
    return AppDatabase(executor);
  }

  static void _setupEncryptedDatabase(Database database, List<int> vaultKey) {
    try {
      final cipherRows = database.select('PRAGMA cipher');
      if (cipherRows.isEmpty) {
        throw const CipherUnavailableException();
      }
      final hexKey = bytesToHex(vaultKey);
      database.execute("PRAGMA cipher = 'sqlcipher'");
      database.execute('PRAGMA key = "x\'$hexKey\'"');
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('PRAGMA hmac_check = 1');
      database.select('SELECT count(*) FROM sqlite_master');
    } on CipherUnavailableException {
      rethrow;
    } on SqliteException catch (error) {
      if (error.message.toLowerCase().contains('cipher')) {
        throw const CipherUnavailableException();
      }
      throw const VaultCorruptedException();
    } finally {
      clearBytes(vaultKey);
    }
  }
}
