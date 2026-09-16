/// `SyncSetup` (§9.9): the keyring's cloud round trip.
///
/// The keyring is what makes a new device possible: it carries every
/// epoch's wrapped master key (device + recovery forms) plus the KDF
/// parameters. It is sealed under `K_cloud` (Envelope v1, purpose
/// `keyring`) before it ever leaves the device, exactly like a blob.
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';

final class SyncSetup {
  const SyncSetup({
    required this.keyManager,
    required this.crypto,
    required this.cloud,
    required this.activeKeyEpoch,
    this.keyringRemoteName = 'v1/keyring.bin',
  });

  final KeyManager keyManager;
  final CryptoEngine crypto;
  final CloudProvider cloud;
  final int Function() activeKeyEpoch;

  /// §9.2 layout: the keyring sits next to `blobs/` and `logs/`.
  final String keyringRemoteName;

  /// §9.9 step 2 (and every rotation afterwards): seal the current
  /// keyring and upload it. Overwrites by name, idempotently.
  Future<Result<void, VaultFailure>> uploadKeyring({
    required DeviceId deviceId,
  }) => guardUseCase(() async {
    final exported = await keyManager.exportKeyring(deviceId: deviceId);
    if (exported.isErr) {
      return Err(exported.errOrNull!);
    }
    final json = keyringToJson(exported.okOrNull!);
    final sealed = await crypto.sealSmall(
      utf8.encode(json),
      keyEpoch: activeKeyEpoch(),
      purpose: EnvelopePurpose.keyring,
    );
    if (sealed.isErr) {
      return Err(sealed.errOrNull!);
    }
    final bytes = sealed.okOrNull!;
    final put = await cloud.put(
      keyringRemoteName,
      Stream.value(bytes),
      totalBytes: bytes.length,
    );
    return put.map((_) {});
  });

  /// §9.9 steps 2–4 for a wiped or new device: find the keyring, open it
  /// with the recovery passphrase, rewrap MK under this device's Keystore
  /// and the fresh [pin].
  Future<Result<void, VaultFailure>> restoreKeyring({
    required String pin,
    required String recoveryPassphrase,
  }) => guardUseCase(() async {
    final listed = await cloud.list(namePrefix: keyringRemoteName);
    if (listed.isErr) {
      return Err(listed.errOrNull!);
    }
    final remote = listed.okOrNull!
        .where((o) => o.name == keyringRemoteName)
        .firstOrNull;
    if (remote == null) {
      return const Err(RemoteObjectMissing('v1/keyring.bin'));
    }
    final got = await cloud.get(remote.remoteId);
    if (got.isErr) {
      return Err(got.errOrNull!);
    }
    final bytes = <int>[];
    await got.okOrNull!.forEach(bytes.addAll);
    final opened = await crypto.openSmall(
      bytes,
      expectedPurpose: EnvelopePurpose.keyring,
    );
    if (opened.isErr) {
      return Err(opened.errOrNull!);
    }
    final keyring = keyringFromJson(utf8.decode(opened.okOrNull!));
    return keyManager.importKeyring(
      keyring: keyring,
      recoveryPassphrase: recoveryPassphrase,
      pin: pin,
    );
  });
}

// ── Keyring JSON codec ────────────────────────────────────────────────────

String keyringToJson(RecoveryKeyringBlob keyring) => jsonEncode({
  'formatVersion': keyring.formatVersion,
  'deviceId': keyring.deviceId,
  'createdAt': keyring.createdAt.millisecondsSinceEpoch,
  'epochs': [
    for (final epoch in keyring.epochs)
      {
        'epoch': epoch.epoch,
        'createdAt': epoch.createdAt.millisecondsSinceEpoch,
        'retiredAt': epoch.retiredAt?.millisecondsSinceEpoch,
        'wrapAlgorithm': epoch.wrapAlgorithm,
        'wrappedMkDevice': base64Encode(epoch.wrappedMkDevice),
        'wrappedMkRecovery': epoch.wrappedMkRecovery == null
            ? null
            : base64Encode(epoch.wrappedMkRecovery!),
        'kdfParamsJson': epoch.kdfParamsJson,
        'keystoreAlias': epoch.keystoreAlias,
        'strongbox': epoch.strongbox,
      },
  ],
});

RecoveryKeyringBlob keyringFromJson(String json) {
  final map = (jsonDecode(json) as Map<Object?, Object?>)
      .cast<String, Object?>();
  DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  DateTime? atOrNull(int? ms) => ms == null ? null : at(ms);
  return RecoveryKeyringBlob(
    formatVersion: (map['formatVersion'] as num).toInt(),
    deviceId: map['deviceId']! as String,
    createdAt: at((map['createdAt'] as num).toInt()),
    epochs: [
      for (final e in (map['epochs']! as List<Object?>)
          .cast<Map<Object?, Object?>>())
        KeyEpoch(
          epoch: (e['epoch'] as num).toInt(),
          createdAt: at((e['createdAt'] as num).toInt()),
          retiredAt: atOrNull((e['retiredAt'] as num?)?.toInt()),
          wrapAlgorithm: e['wrapAlgorithm']! as String,
          wrappedMkDevice: base64Decode(e['wrappedMkDevice']! as String),
          wrappedMkRecovery: (e['wrappedMkRecovery'] as String?) == null
              ? null
              : base64Decode(e['wrappedMkRecovery']! as String),
          kdfParamsJson: e['kdfParamsJson'] as String?,
          keystoreAlias: e['keystoreAlias']! as String,
          strongbox: e['strongbox']! as bool,
        ),
    ],
  );
}
