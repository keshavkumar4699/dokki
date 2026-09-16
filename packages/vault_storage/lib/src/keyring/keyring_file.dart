/// `KeyEpochRepository` over a file (§7.1 `keyring/keyring.json`).
///
/// The keyring must be readable BEFORE the vault is unlocked — it is what
/// the unlock reads — so it cannot live inside the SQLCipher database. Its
/// contents are non-secret by construction: wrapped keys and KDF
/// parameters (§8.1). The `key_epochs` table is a mirror kept for the
/// `blobs.key_epoch` foreign key; the file is the source of truth.
///
/// Writes are atomic (temp + rename) so a crash mid-write can never leave
/// a vault whose keyring is half a JSON document.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';

final class KeyringFile implements KeyEpochRepository {
  KeyringFile({required String rootDir})
    : _file = File(p.join(rootDir, 'keyring', 'keyring.json'));

  static const formatVersion = 1;

  final File _file;

  bool get exists => _file.existsSync();

  @override
  Future<Result<List<KeyEpoch>, VaultFailure>> loadEpochs() => guardIo(
    'keyring.load',
    () async {
      if (!_file.existsSync()) {
        return const <KeyEpoch>[];
      }
      final map = (jsonDecode(await _file.readAsString()) as Map)
          .cast<String, Object?>();
      final version = map['formatVersion'] as int? ?? 0;
      if (version != formatVersion) {
        throw FormatException('unsupported keyring format $version');
      }
      return [
        for (final raw in (map['epochs'] as List).cast<Map<Object?, Object?>>())
          _decode(raw.cast<String, Object?>()),
      ]..sort((a, b) => a.epoch.compareTo(b.epoch));
    },
  );

  @override
  Future<Result<KeyEpoch?, VaultFailure>> activeEpoch() =>
      loadEpochs().map((rows) => rows.where((e) => e.isActive).firstOrNull);

  @override
  Future<Result<void, VaultFailure>> insertEpoch(KeyEpoch epoch) =>
      _rewrite((rows) => [...rows.where((e) => e.epoch != epoch.epoch), epoch]);

  @override
  Future<Result<void, VaultFailure>> retireEpoch(
    int epoch,
    DateTime retiredAt,
  ) => _rewrite(
    (rows) => [
      for (final row in rows)
        if (row.epoch == epoch && row.isActive)
          KeyEpoch(
            epoch: row.epoch,
            createdAt: row.createdAt,
            retiredAt: retiredAt,
            wrapAlgorithm: row.wrapAlgorithm,
            wrappedMkDevice: row.wrappedMkDevice,
            wrappedMkRecovery: row.wrappedMkRecovery,
            kdfParamsJson: row.kdfParamsJson,
            keystoreAlias: row.keystoreAlias,
            strongbox: row.strongbox,
          )
        else
          row,
    ],
  );

  Future<Result<void, VaultFailure>> _rewrite(
    List<KeyEpoch> Function(List<KeyEpoch> rows) transform,
  ) => loadEpochs().asyncFlatMap(
    (rows) => guardIo('keyring.write', () async {
      final updated = transform(rows)
        ..sort((a, b) => a.epoch.compareTo(b.epoch));
      await _file.parent.create(recursive: true);
      final tmp = File('${_file.path}.part');
      await tmp.writeAsString(
        jsonEncode({
          'formatVersion': formatVersion,
          'epochs': updated.map(_encode).toList(growable: false),
        }),
        flush: true,
      );
      await tmp.rename(_file.path);
    }),
  );

  static Map<String, Object?> _encode(KeyEpoch e) => {
    'epoch': e.epoch,
    'createdAt': e.createdAt.millisecondsSinceEpoch,
    'retiredAt': e.retiredAt?.millisecondsSinceEpoch,
    'wrapAlgorithm': e.wrapAlgorithm,
    'wrappedMkDevice': base64Encode(e.wrappedMkDevice),
    'wrappedMkRecovery': e.wrappedMkRecovery == null
        ? null
        : base64Encode(e.wrappedMkRecovery!),
    'kdfParamsJson': e.kdfParamsJson,
    'keystoreAlias': e.keystoreAlias,
    'strongbox': e.strongbox,
  };

  static KeyEpoch _decode(Map<String, Object?> m) => KeyEpoch(
    epoch: m['epoch']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      m['createdAt']! as int,
      isUtc: true,
    ),
    retiredAt: m['retiredAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            m['retiredAt']! as int,
            isUtc: true,
          ),
    wrapAlgorithm: m['wrapAlgorithm']! as String,
    wrappedMkDevice: base64Decode(m['wrappedMkDevice']! as String),
    wrappedMkRecovery: m['wrappedMkRecovery'] == null
        ? null
        : base64Decode(m['wrappedMkRecovery']! as String),
    kdfParamsJson: m['kdfParamsJson'] as String?,
    keystoreAlias: m['keystoreAlias']! as String,
    strongbox: m['strongbox'] as bool? ?? false,
  );
}
