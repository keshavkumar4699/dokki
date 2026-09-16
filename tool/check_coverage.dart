/// CI coverage gate (§13.8): runs `flutter test --coverage` for each
/// package and fails under its threshold. Skips packages without tests.
///
/// Usage: `dart run tool/check_coverage.dart`
library;

import 'dart:convert';
import 'dart:io';

/// §13.8 coverage targets. Only packages with gates appear here.
const _gates = <String, int>{
  'packages/vault_domain': 95,
  'packages/vault_crypto': 95,
  'packages/vault_sync': 90,
  'packages/vault_export': 85,
  'packages/vault_persistence': 80,
  'app': 40,
};

Future<void> main() async {
  final failures = <String>[];
  for (final entry in _gates.entries) {
    final pkg = entry.key;
    final threshold = entry.value;
    if (!Directory('$pkg/test').existsSync()) {
      stderr.writeln('skip $pkg (no test dir)');
      continue;
    }
    final result = await Process.run(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['test', '--coverage'],
      workingDirectory: pkg,
    );
    if (result.exitCode != 0) {
      failures.add('$pkg: tests failed\n${result.stderr}');
      continue;
    }
    final lcov = File('$pkg/coverage/lcov.info');
    if (!lcov.existsSync()) {
      failures.add('$pkg: no coverage/lcov.info produced');
      continue;
    }
    final pct = _coverPercent(await lcov.readAsString());
    final mark = pct >= threshold ? 'ok' : 'FAIL';
    stdout.writeln('$mark $pkg: ${pct.toStringAsFixed(1)}% (gate $threshold%)');
    if (pct < threshold) {
      failures.add('$pkg: ${pct.toStringAsFixed(1)}% < $threshold%');
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln('\nCOVERAGE GATE FAILED:\n${failures.join('\n')}');
    exitCode = 1;
  } else {
    stdout.writeln('coverage: OK');
  }
}

/// Line coverage from lcov: LF (lines found) vs LH (lines hit).
double _coverPercent(String lcov) {
  var found = 0;
  var hit = 0;
  for (final line in const LineSplitter().convert(lcov)) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }
  return found == 0 ? 0 : hit / found * 100;
}
