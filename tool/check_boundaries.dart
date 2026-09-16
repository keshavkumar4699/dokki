// CI boundary checker for the dokki workspace.
//
// Enforces the package-level architecture rules from docs/ARCHITECTURE.md §3:
//   - dependency direction (infrastructure → domain, never domain → infra)
//   - app/lib/features contains presentation only
//   - app/lib/bootstrap/composition_root.dart is the only place that imports
//     concrete infrastructure
//   - raw print/debugPrint/dart:developer log only inside the VaultLog facade
//   - DateTime.now() / Random( / Uuid() only in app/lib/bootstrap (injected
//     Clock/IdGenerator/RandomSource everywhere else)
//   - try/catch only inside files named error_boundary.dart
//
// Exit code 0 = pass, 1 = violation. Run with `dart run tool/check_boundaries.dart`.
library;

import 'dart:io';

const _exemptPatterns = <String>[
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
  '/generated/',
  '.iml',
];

bool _isExempt(String path) => _exemptPatterns.any(path.contains);

bool _isTest(String path) =>
    path.contains('/test/') || path.endsWith('_test.dart');

final class Violation {
  const Violation(this.rule, this.path, this.line, this.detail);

  final String rule;
  final String path;
  final int line;
  final String detail;

  @override
  String toString() => '$rule: $path:$line — $detail';
}

final class BoundaryChecker {
  BoundaryChecker({required this.root, this.reporter = _stderrReporter});

  final String root;
  final void Function(String message) reporter;

  static void _stderrReporter(String message) => stderr.writeln(message);

  final List<Violation> violations = <Violation>[];

  static final _infraPackages = <String>{
    'vault_crypto',
    'vault_persistence',
    'vault_storage',
    'vault_imaging',
    'vault_pdf',
    'vault_export',
    'vault_sync',
    'vault_drive',
    'platform_android',
  };

  /// package dir (relative, no trailing slash) → forbidden import prefixes.
  static final Map<String, List<String>>
  packageForbiddenImports = <String, List<String>>{
    'packages/vault_domain': <String>[
      'package:drift/',
      'package:googleapis',
      'package:flutter/',
      'dart:io',
      'package:cryptography',
      'package:pointycastle',
      'package:image/',
    ],
    'packages/vault_app_core': <String>[
      'package:drift/',
      'package:googleapis',
      'package:flutter/',
      'dart:io',
      'package:vault_crypto/',
      'package:vault_persistence/',
      'package:vault_storage/',
      'package:vault_imaging/',
      'package:vault_pdf/',
      'package:vault_export/',
      'package:vault_sync/',
      'package:vault_drive/',
      'package:platform_android/',
    ],
    'packages/vault_crypto': <String>[
      'package:drift/',
      'package:googleapis',
      'package:image/',
    ],
    'packages/vault_persistence': <String>[
      'package:googleapis',
      'package:image/',
      'package:flutter/widgets.dart',
    ],
    'packages/vault_storage': <String>['package:drift/', 'package:googleapis'],
    'packages/vault_imaging': <String>[
      'package:drift/',
      'package:googleapis',
      'package:vault_pdf/',
    ],
    'packages/vault_pdf': <String>['package:drift/', 'package:googleapis'],
    'packages/vault_export': <String>['package:drift/', 'package:googleapis'],
    'packages/vault_sync': <String>['package:drift/', 'package:googleapis'],
    'packages/vault_drive': <String>[
      'package:drift/',
      'package:image/',
      'package:flutter/widgets.dart',
    ],
    'packages/platform_android': <String>[
      'package:vault_domain/',
      'package:vault_crypto/',
      'package:drift/',
      'package:googleapis',
    ],
  };

  static const _featuresForbidden = <String>[
    'package:drift/',
    'package:googleapis',
    'dart:io',
    'package:crypto/',
    'package:vault_crypto/',
    'package:vault_persistence/',
    'package:vault_storage/',
    'package:vault_imaging/',
    'package:vault_pdf/',
    'package:vault_export/',
    'package:vault_sync/',
    'package:vault_drive/',
    'package:platform_android/',
  ];

  static final _logSinkAllowlist = <String>{
    'packages/vault_domain/lib/src/logging/vault_log.dart',
  };

  static final _clockAllowlistPrefixes = <String>[
    'app/lib/bootstrap/',
    'app/lib/main.dart',
  ];

  void run() {
    for (final entry in packageForbiddenImports.entries) {
      _checkPackageForbidden(_join(root, entry.key), entry.value);
    }
    _checkFeatures();
    _checkCompositionRoot();
    _checkLogging();
    _checkInjectedClock();
    _checkErrorBoundaries();
  }

  String _join(String a, String b) => '$a${Platform.pathSeparator}$b';

  /// [root] with forward slashes and a trailing `/`, so allowlist prefixes
  /// like `app/lib/bootstrap/` match regardless of where the repo lives.
  String get _normalizedRoot {
    final normalized = root.replaceAll(r'\', '/');
    return normalized.endsWith('/') ? normalized : '$normalized/';
  }

  Iterable<File> _dartFiles(Directory dir) {
    if (!dir.existsSync()) {
      return const <File>[];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'));
  }

  void _checkPackageForbidden(String dir, List<String> forbidden) {
    for (final file in _dartFiles(Directory(dir))) {
      _scanFile(
        file.path,
        forbidden,
        'forbidden-import',
        (String import) => import.startsWith('package:')
            ? forbidden.any(import.startsWith)
            : forbidden.contains(import),
      );
    }
  }

  void _checkFeatures() {
    for (final file in _dartFiles(Directory(_join(root, 'app/lib/features')))) {
      _scanFile(
        file.path,
        _featuresForbidden,
        'features-presentation-only',
        (String import) => _featuresForbidden.any(import.startsWith),
      );
    }
  }

  void _checkCompositionRoot() {
    final infraPrefixes = _infraPackages
        .map((String p) => 'package:$p/')
        .toList(growable: false);
    for (final file in _dartFiles(Directory(_join(root, 'app/lib')))) {
      if (file.path.replaceAll(r'\', '/').contains('lib/bootstrap/')) {
        continue;
      }
      _scanFile(
        file.path,
        infraPrefixes,
        'composition-root-only',
        (String import) => infraPrefixes.any(import.startsWith),
      );
    }
  }

  void _checkLogging() {
    for (final entry in Directory(root).listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) {
        continue;
      }
      final path = entry.path.replaceAll(r'\', '/');
      if (_isTest(path) || _isExempt(path) || path.contains('/.dart_tool/')) {
        continue;
      }
      final allowed = _logSinkAllowlist.any(path.endsWith);
      if (allowed) {
        continue;
      }
      final lines = entry.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        if (trimmed.startsWith("import 'dart:developer'") ||
            trimmed.startsWith('import "dart:developer"') ||
            trimmed.startsWith('print(') ||
            trimmed.startsWith('debugPrint(')) {
          violations.add(
            Violation(
              'raw-logging',
              path,
              i + 1,
              'print/debugPrint/dart:developer only inside the VaultLog facade',
            ),
          );
        }
      }
    }
  }

  void _checkInjectedClock() {
    for (final entry in Directory(root).listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) {
        continue;
      }
      final path = entry.path.replaceAll(r'\', '/');
      if (_isTest(path) ||
          _isExempt(path) ||
          path.contains('/.dart_tool/') ||
          path.contains('/tool/')) {
        continue;
      }
      final relative = path.startsWith(_normalizedRoot)
          ? path.substring(_normalizedRoot.length)
          : path;
      final allowed = _clockAllowlistPrefixes.any(relative.startsWith);
      if (allowed) {
        continue;
      }
      final lines = entry.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // Comments may mention the banned names when documenting the rule.
        if (lines[i].trimLeft().startsWith('//')) {
          continue;
        }
        if (RegExp(
          r'DateTime\.now\(|Random\(|Random\.secure\(|Uuid\(',
        ).hasMatch(lines[i])) {
          violations.add(
            Violation(
              'injected-clock',
              path,
              i + 1,
              'use injected Clock/IdGenerator/RandomSource; real sources live '
                  'in app/lib/bootstrap only',
            ),
          );
        }
      }
    }
  }

  void _checkErrorBoundaries() {
    final packages = Directory(_join(root, 'packages'));
    if (!packages.existsSync()) {
      return;
    }
    for (final dir in packages.listSync().whereType<Directory>()) {
      final lib = Directory(_join(dir.path, 'lib'));
      if (!lib.existsSync()) {
        continue;
      }
      for (final file in _dartFiles(lib)) {
        final path = file.path.replaceAll(r'\', '/');
        if (_isExempt(path) ||
            path.contains('/lib/src/failures/') ||
            path.endsWith('/lib/src/result.dart') ||
            path.contains('logging/')) {
          continue;
        }
        final catchAllowed = path.endsWith('/error_boundary.dart');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'\bcatch\s*\(').hasMatch(lines[i]) && !catchAllowed) {
            violations.add(
              Violation(
                'error-boundary',
                path,
                i + 1,
                'try/catch only inside error_boundary.dart files',
              ),
            );
          }
        }
      }
    }
  }

  void _scanFile(
    String path,
    List<String> needles,
    String rule,
    bool Function(String import) matches,
  ) {
    final lines = File(path).readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ') || line.contains(' as ')) {
        continue;
      }
      final m = RegExp("""^import ['"]([^'"]+)['"]""").firstMatch(line);
      if (m == null) {
        continue;
      }
      if (matches(m.group(1)!)) {
        violations.add(
          Violation(
            rule,
            path.replaceAll(r'\', '/'),
            i + 1,
            'forbidden import: ${m.group(1)}',
          ),
        );
      }
    }
  }
}

Future<void> main(List<String> args) async {
  final root = args.isEmpty ? Directory.current.path : args.first;
  final checker = BoundaryChecker(root: root)..run();
  if (checker.violations.isEmpty) {
    stdout.writeln('boundaries: OK');
    return;
  }
  checker.reporter('BOUNDARY VIOLATIONS (${checker.violations.length}):');
  for (final v in checker.violations) {
    checker.reporter('  $v');
  }
  exitCode = 1;
}
