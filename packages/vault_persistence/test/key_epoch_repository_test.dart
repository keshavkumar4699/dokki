/// `KeyEpochRepositoryImpl`: the `key_epochs` mirror must be re-insertable
/// while blobs reference it (the keyring file is re-mirrored on every open).
library;

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_persistence/vault_persistence.dart';

import 'support/fixtures.dart';

void main() {
  test(
    're-inserting a referenced epoch upserts instead of replacing',
    () async {
      final db = await openTestDb(); // inserts epoch 1
      addTearDown(db.close);
      final repo = EntryRepositoryImpl(db, activeKeyEpoch: () => 1);
      final fx = Fixtures();
      unwrap(await repo.createEntry(fx.newEntry(EntryType.photo)));

      final epochs = KeyEpochRepositoryImpl(db);
      final again = await epochs.insertEpoch(
        KeyEpoch(
          epoch: 1,
          createdAt: DateTime.utc(2026),
          wrapAlgorithm: 'TEST',
          wrappedMkDevice: const [9, 9, 9],
          keystoreAlias: 'test.kek.1',
          strongbox: true,
        ),
      );
      expect(again.isOk, isTrue, reason: '${again.errOrNull?.cause}');
      final rows = unwrap(await epochs.loadEpochs());
      expect(rows.single.wrappedMkDevice, [9, 9, 9]);
      expect(rows.single.strongbox, isTrue);
    },
  );
}
