/// Platform security controls (§8.5): `dokki/vault_security`.
library;

import 'package:flutter/services.dart';

import 'error_boundary.dart';

final class NativeSecurity {
  const NativeSecurity();

  static const MethodChannel _channel = MethodChannel('dokki/vault_security');

  /// `FLAG_SECURE` on the vault activity plus
  /// `setRecentsScreenshotEnabled(false)` on API 33+. Applied ALWAYS, not
  /// conditionally (§8.5).
  Future<void> applySecureWindow() =>
      guardChannel(() => _channel.invokeMethod<void>('applySecureWindow'));

  /// Whether a secure device lock (PIN/pattern/password) is set. The app
  /// refuses to create a vault without one (§8.3).
  Future<bool> hasDeviceLock() async {
    final result = await guardChannel(
      () => _channel.invokeMethod<bool>('hasDeviceLock'),
    );
    return result ?? false;
  }

  /// Free bytes on the vault's filesystem (§7.6); -1 when unmeasurable.
  Future<int> freeDiskSpace() async {
    final result = await guardChannel(
      () => _channel.invokeMethod<int>('freeDiskSpace'),
    );
    return result ?? -1;
  }

  /// Advisory root/debugger/emulator signals (§8.7 T4, Phase 9).
  Future<List<String>> rootSignals() async {
    final result = await guardChannel(
      () => _channel.invokeMethod<Object?>('rootSignals'),
    );
    if (result is List<Object?>) {
      return result.map((Object? s) => s as String).toList(growable: false);
    }
    return const [];
  }
}
