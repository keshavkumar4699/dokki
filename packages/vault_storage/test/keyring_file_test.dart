/// `KeyringFile`: the pre-unlock source of truth for key epochs.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_storage/vault_storage.dart';

KeyEpoch _epoch(int n, {DateTime? retiredAt}) => KeyEpoch(
  epoch: n,
  createdAt: DateTime.utc(2026, 1, n),
  retiredAt: retiredAt,
  wrapAlgorithm: 'KEYSTORE_AES_GCM_V1',
  wrappedMkDevice: [n, n, n],
  wrappedMkRecovery: [9, 9],
  kdfParamsJson: '{"m":1}',
  keystoreAlias: 'vault.kek.$n',
  strongbox: n.isEven,
);

void main() {
  late Directory root;
  late KeyringFile keyring;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dokki_keyring_');
    keyring = KeyringFile(rootDir: root.path);
  });

  tearDown(() => root.delete(recursive: true));

  test('empty until the first epoch is written', () async {
    expect(keyring.exists, isFalse);
    expect((await keyring.loadEpochs()).okOrNull, isEmpty);
    expect((await keyring.activeEpoch()).okOrNull, isNull);
  });

  test('round-trips every field and sorts by epoch', () async {
    await keyring.insertEpoch(_epoch(2));
    await keyring.insertEpoch(_epoch(1));
    final rows = (await keyring.loadEpochs()).okOrNull!;
    expect(rows.map((e) => e.epoch), [1, 2]);
    final second = rows[1];
    expect(second.wrappedMkDevice, [2, 2, 2]);
    expect(second.wrappedMkRecovery, [9, 9]);
    expect(second.kdfParamsJson, '{"m":1}');
    expect(second.keystoreAlias, 'vault.kek.2');
    expect(second.strongbox, isTrue);
    expect(second.createdAt, DateTime.utc(2026, 1, 2));
    expect(
      File(p.join(root.path, 'keyring', 'keyring.json')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(root.path, 'keyring', 'keyring.json.part')).existsSync(),
      isFalse,
    );
  });

  test('insertEpoch replaces an existing epoch in place', () async {
    await keyring.insertEpoch(_epoch(1));
    await keyring.insertEpoch(
      KeyEpoch(
        epoch: 1,
        createdAt: DateTime.utc(2026),
        wrapAlgorithm: 'X',
        wrappedMkDevice: const [42],
        keystoreAlias: 'a',
        strongbox: false,
      ),
    );
    final rows = (await keyring.loadEpochs()).okOrNull!;
    expect(rows, hasLength(1));
    expect(rows.single.wrappedMkDevice, [42]);
    expect(rows.single.wrappedMkRecovery, isNull);
  });

  test(
    'retireEpoch clears the active flag; a fresh instance sees it',
    () async {
      await keyring.insertEpoch(_epoch(1));
      await keyring.insertEpoch(_epoch(2));
      await keyring.retireEpoch(1, DateTime.utc(2026, 2));
      final reopened = KeyringFile(rootDir: root.path);
      final active = (await reopened.activeEpoch()).okOrNull;
      expect(active?.epoch, 2);
      expect(
        (await reopened.loadEpochs()).okOrNull!.first.retiredAt,
        DateTime.utc(2026, 2),
      );
    },
  );

  test('a corrupt file is a failure, not a crash', () async {
    final file = File(p.join(root.path, 'keyring', 'keyring.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{"formatVersion": 99}');
    expect(file.existsSync(), isTrue);
    expect((await keyring.loadEpochs()).isErr, isTrue);
  });
}
