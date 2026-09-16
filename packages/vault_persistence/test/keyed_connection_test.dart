/// SQLCipher wiring (§15.1, R6): a keyed open works, a wrong key fails
/// closed, and the canary refuses a non-cipher build. Runs only where the
/// SQLCipher build of sqlite3 is loaded (Android/iOS); on a plain host the
/// canary itself is what gets tested.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';
import 'package:vault_persistence/vault_persistence.dart';

bool _cipherAvailable() {
  final db = sqlite3.sqlite3.openInMemory();
  try {
    final rows = db.select('PRAGMA cipher_version');
    return rows.isNotEmpty &&
        ((rows.first.columnAt(0) as String?)?.isNotEmpty ?? false);
  } finally {
    db.dispose();
  }
}

void main() {
  final key = List<int>.generate(32, (i) => i * 3 % 251);

  test('the canary refuses a plain sqlite3 build', () {
    final db = sqlite3.sqlite3.openInMemory();
    addTearDown(db.dispose);
    if (_cipherAvailable()) {
      expect(() => assertCipherActive(db), returnsNormally);
    } else {
      expect(() => assertCipherActive(db), throwsStateError);
    }
  });

  test('isPlaintextSqlite recognises the magic header', () async {
    final dir = await Directory.systemTemp.createTemp('dokki_db_');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'v.db');
    expect(isPlaintextSqlite(path), isFalse);
    final db = AppDatabase(openVaultConnection(path));
    await db.customSelect('SELECT 1').get();
    await db.close();
    expect(isPlaintextSqlite(path), isTrue);
  });

  test(
    'keyed open round-trips; wrong key and plaintext open both fail closed',
    () async {
      final dir = await Directory.systemTemp.createTemp('dokki_db_');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'v.db');

      final db = AppDatabase(openVaultConnection(path, key: key));
      await db
          .into(db.appMeta)
          .insert(
            AppMetaCompanion.insert(
              key: 'canary',
              value: Uint8List.fromList([1]),
            ),
          );
      await db.close();
      expect(isPlaintextSqlite(path), isFalse);

      final wrong = AppDatabase(
        openVaultConnection(path, key: List<int>.filled(32, 1)),
      );
      await expectLater(
        wrong.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
      await wrong.close();

      final reopened = AppDatabase(openVaultConnection(path, key: key));
      final rows = await reopened.select(reopened.appMeta).get();
      expect(rows.single.key, 'canary');
      await reopened.close();
    },
    skip: _cipherAvailable() ? false : 'needs the SQLCipher build of sqlite3',
  );

  test(
    'encryptPlaintextDatabase migrates a Phase-1 file in place',
    () async {
      final dir = await Directory.systemTemp.createTemp('dokki_db_');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'v.db');
      final plain = AppDatabase(openVaultConnection(path));
      await plain
          .into(plain.appMeta)
          .insert(
            AppMetaCompanion.insert(key: 'k', value: Uint8List.fromList([7])),
          );
      await plain.close();
      expect(isPlaintextSqlite(path), isTrue);

      encryptPlaintextDatabase(path, key);
      expect(isPlaintextSqlite(path), isFalse);
      final db = AppDatabase(openVaultConnection(path, key: key));
      expect((await db.select(db.appMeta).get()).single.value, [7]);
      await db.close();
    },
    skip: _cipherAvailable() ? false : 'needs the SQLCipher build of sqlite3',
  );
}
