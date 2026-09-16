/// The logging facade (§8.5).
///
/// This file is the ONLY place in the codebase where `dart:developer`'s
/// `log` may be imported (enforced by `tool/check_boundaries.dart`). All
/// other code routes through [VaultLog]. A compile-time release guard keeps
/// debug logs out of production builds.
library;

import 'dart:developer' as developer;

enum VaultLogLevel { debug, info, warning, error }

/// Where log lines eventually go.
abstract interface class VaultLogSink {
  void write(VaultLogLevel level, String message);
}

/// The one logging entry point.
final class VaultLog {
  VaultLog({required this.sink, required this.debugEnabled});

  final VaultLogSink sink;

  /// `kReleaseMode`-bound. When false, [d] calls are dropped.
  final bool debugEnabled;

  void d(String message) {
    if (!debugEnabled) {
      return;
    }
    sink.write(VaultLogLevel.debug, message);
  }

  void i(String message) => sink.write(VaultLogLevel.info, message);

  void w(String message) => sink.write(VaultLogLevel.warning, message);

  /// Logs a failure. Only the stable [code] is logged — never `cause`'s
  /// message, which may contain a file path (§12.4).
  void e(String message, {String? failureCode}) {
    final code = failureCode == null ? '' : ' [$failureCode]';
    sink.write(VaultLogLevel.error, '$message$code');
  }
}

/// Default sink: `dart:developer` log, prefixed by level.
final class DeveloperLogSink implements VaultLogSink {
  const DeveloperLogSink();

  @override
  void write(VaultLogLevel level, String message) {
    final prefix = switch (level) {
      VaultLogLevel.debug => 'D',
      VaultLogLevel.info => 'I',
      VaultLogLevel.warning => 'W',
      VaultLogLevel.error => 'E',
    };
    developer.log(message, name: 'dokki.$prefix');
  }
}

/// Stdout sink for debug builds on device: `dart:developer` output only
/// reaches an attached tool, whereas `print` lands in logcat. Never wire
/// this in release (§8.5: no raw logging outside this facade).
final class ConsoleLogSink implements VaultLogSink {
  const ConsoleLogSink();

  @override
  void write(VaultLogLevel level, String message) {
    // ignore: avoid_print
    print('[dokki.${level.name}] $message');
  }
}
