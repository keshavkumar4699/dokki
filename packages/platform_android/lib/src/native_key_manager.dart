/// Key-management channel: `dokki/vault_keymanager`.
///
/// The master key never crosses the channel. Kotlin generates it, wraps it
/// under the Keystore-bound KEK and under Argon2id(recovery passphrase),
/// and holds the unwrapped MK in a native session. Dart persists only the
/// wrapped blobs and KDF parameters (`KeyEpochRepository`) and hands them
/// back for every unwrap — Kotlin stores nothing itself.
///
/// Protocol (byte arrays base64):
///   createVault {pin, recoveryPassphrase, epoch}
///     → { wrappedMkDevice, wrappedMkRecovery, kdfParamsJson, alias,
///         strongbox }
///   unlock {pin, epochs: [{epoch, alias, wrappedMkDevice, kdfParamsJson}]}
///     → {}                     (binds every epoch's MK in the session)
///   lock                                       → {}
///   isUnlocked                                 → bool
///   verifyPin {pin, alias, wrappedMkDevice, kdfParamsJson} → bool
///   verifyRecoveryPassphrase {passphrase, wrappedMkRecovery, kdfParamsJson}
///     → bool
///   changeRecovery {epoch, newPassphrase, kdfParamsJson}
///     → { wrappedMkRecovery, kdfParamsJson }
///   deriveDbKey                                → { key }
///   importUnwrapped {epoch, wrappedMkRecovery, kdfParamsJson, passphrase,
///                    pin}
///     → { wrappedMkDevice, wrappedMkRecovery, kdfParamsJson, alias,
///         strongbox }
///
/// Error codes: NO_DEVICE_LOCK, KEY_INVALIDATED, BIOMETRIC_CHANGED,
/// AUTH_FAILED (wrong PIN / passphrase), USER_CANCELLED (auth prompt
/// dismissed), LOCKED.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'error_boundary.dart';

/// The wrapped material for one epoch, as Kotlin needs it to unwrap.
final class EpochMaterial {
  const EpochMaterial({
    required this.epoch,
    required this.keystoreAlias,
    required this.wrappedMkDevice,
    required this.wrappedMkRecovery,
    required this.kdfParamsJson,
  });

  final int epoch;
  final String keystoreAlias;
  final Uint8List wrappedMkDevice;
  final Uint8List? wrappedMkRecovery;
  final String kdfParamsJson;

  Map<String, Object?> toJson() => {
    'epoch': epoch,
    'alias': keystoreAlias,
    'wrappedMkDevice': base64Encode(wrappedMkDevice),
    'wrappedMkRecovery': wrappedMkRecovery == null
        ? null
        : base64Encode(wrappedMkRecovery!),
    'kdfParamsJson': kdfParamsJson,
  };
}

final class NativeKeyManagerBridge {
  const NativeKeyManagerBridge();

  static const MethodChannel _channel = MethodChannel('dokki/vault_keymanager');

  /// Whether the Kotlin side implements this channel at all. The
  /// composition root uses it to choose between the native and the
  /// software (dev) key backend.
  Future<bool> isAvailable() async {
    try {
      await _channel.invokeMethod<bool>('isUnlocked');
      return true;
    } on MissingPluginException {
      return false;
    }
  }

  Future<CreateVaultResult> createVault({
    required String pin,
    required String recoveryPassphrase,
    required int epoch,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('createVault', {
        'pin': pin,
        'recoveryPassphrase': recoveryPassphrase,
        'epoch': epoch,
      }),
    );
    return CreateVaultResult.fromJson(result!);
  }

  Future<void> unlock({
    required String pin,
    required List<EpochMaterial> epochs,
  }) => guardChannel(
    () => _channel.invokeMethod<void>('unlock', {
      'pin': pin,
      'epochs': epochs.map((e) => e.toJson()).toList(growable: false),
    }),
  );

  Future<void> lock() =>
      guardChannel(() => _channel.invokeMethod<void>('lock'));

  Future<bool> isUnlocked() async {
    final result = await guardChannel(
      () => _channel.invokeMethod<bool>('isUnlocked'),
    );
    return result ?? false;
  }

  Future<bool> verifyPin(String pin, EpochMaterial epoch) async {
    final result = await guardChannel(
      () => _channel.invokeMethod<bool>('verifyPin', {
        'pin': pin,
        'alias': epoch.keystoreAlias,
        'wrappedMkDevice': base64Encode(epoch.wrappedMkDevice),
        'kdfParamsJson': epoch.kdfParamsJson,
      }),
    );
    return result ?? false;
  }

  Future<bool> verifyRecoveryPassphrase(
    String passphrase,
    EpochMaterial epoch,
  ) async {
    final wrapped = epoch.wrappedMkRecovery;
    if (wrapped == null) {
      return false;
    }
    final result = await guardChannel(
      () => _channel.invokeMethod<bool>('verifyRecoveryPassphrase', {
        'passphrase': passphrase,
        'wrappedMkRecovery': base64Encode(wrapped),
        'kdfParamsJson': epoch.kdfParamsJson,
      }),
    );
    return result ?? false;
  }

  /// `K_db = HKDF(MK, 'dokki/vault/kdb/v1')` for SQLCipher — the one
  /// derived key that must reach the Dart heap (§8.4). The caller passes
  /// it to `PRAGMA key` and drops it.
  Future<Uint8List> deriveDbKey() async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('deriveDbKey'),
    );
    return base64Decode(result!['key']! as String);
  }

  Future<RewrapResult> changeRecovery({
    required int epoch,
    required String newPassphrase,
    required String kdfParamsJson,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('changeRecovery', {
        'epoch': epoch,
        'newPassphrase': newPassphrase,
        'kdfParamsJson': kdfParamsJson,
      }),
    );
    return RewrapResult.fromJson(result!);
  }

  /// Bootstrap step 3 (§9.9): unwrap MK from the recovery blob, then wrap
  /// it under this device's Keystore + the new PIN, and unlock.
  Future<CreateVaultResult> importUnwrapped({
    required EpochMaterial epoch,
    required String passphrase,
    required String pin,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('importUnwrapped', {
        'epoch': epoch.epoch,
        'wrappedMkRecovery': base64Encode(epoch.wrappedMkRecovery ?? const []),
        'kdfParamsJson': epoch.kdfParamsJson,
        'passphrase': passphrase,
        'pin': pin,
      }),
    );
    return CreateVaultResult.fromJson(result!);
  }
}

/// `createVault` / `importUnwrapped` output.
final class CreateVaultResult {
  const CreateVaultResult({
    required this.wrappedMkDevice,
    required this.wrappedMkRecovery,
    required this.kdfParamsJson,
    required this.keystoreAlias,
    required this.strongbox,
  });

  factory CreateVaultResult.fromJson(Map<String, Object?> json) =>
      CreateVaultResult(
        wrappedMkDevice: base64Decode(json['wrappedMkDevice']! as String),
        wrappedMkRecovery: base64Decode(json['wrappedMkRecovery']! as String),
        kdfParamsJson: json['kdfParamsJson']! as String,
        keystoreAlias: json['alias']! as String,
        strongbox: json['strongbox'] as bool? ?? false,
      );

  final Uint8List wrappedMkDevice;
  final Uint8List wrappedMkRecovery;
  final String kdfParamsJson;
  final String keystoreAlias;
  final bool strongbox;
}

/// `changeRecovery` output.
final class RewrapResult {
  const RewrapResult({
    required this.wrappedMkRecovery,
    required this.kdfParamsJson,
  });

  factory RewrapResult.fromJson(Map<String, Object?> json) => RewrapResult(
    wrappedMkRecovery: base64Decode(json['wrappedMkRecovery']! as String),
    kdfParamsJson: json['kdfParamsJson']! as String,
  );

  final Uint8List wrappedMkRecovery;
  final String kdfParamsJson;
}
