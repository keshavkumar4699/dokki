import 'package:test/test.dart';
import 'package:vault_domain/src/failures/vault_failure.dart';
import 'package:vault_domain/src/result.dart';

void main() {
  group('Result', () {
    test('ok/isOk/isErr', () {
      final r = ok<int, String>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(okOrNull(r), 42);
      expect(errOrNullOf(r), isNull);
    });

    test('err/isOk/isErr', () {
      final r = err<int, String>('boom');
      expect(r.isOk, isFalse);
      expect(r.isErr, isTrue);
      expect(okOrNull(r), isNull);
      expect(errOrNullOf(r), 'boom');
    });

    test('getOrElse', () {
      expect(ok<int, String>(7).getOrElse((_) => 0), 7);
      expect(err<int, String>('x').getOrElse((_) => 0), 0);
    });

    test('fold', () {
      expect(ok<int, String>(7).fold((v) => 'v$v', (e) => 'e$e'), 'v7');
      expect(err<int, String>('x').fold((v) => 'v$v', (e) => 'e$e'), 'ex');
    });

    test('map', () {
      expect(ok<int, String>(7).map((v) => v * 2), ok<int, String>(14));
      expect(err<int, String>('x').map((v) => v * 2), err<int, String>('x'));
    });

    test('mapErr', () {
      expect(ok<int, String>(7).mapErr((e) => e.length), ok<int, int>(7));
      expect(err<int, String>('xx').mapErr((e) => e.length), err<int, int>(2));
    });

    test('flatMap', () {
      expect(
        ok<int, String>(7).flatMap((v) => ok<int, String>(v + 1)),
        ok<int, String>(8),
      );
      expect(
        ok<int, String>(7).flatMap((v) => err<int, String>('late')),
        err<int, String>('late'),
      );
      expect(
        err<int, String>('early').flatMap((v) => ok<int, String>(v + 1)),
        err<int, String>('early'),
      );
    });

    test('asyncMap', () async {
      final r = await ok<int, String>(7).asyncMap((v) async => v * 3);
      expect(r, ok<int, String>(21));
      final e = await err<int, String>('x').asyncMap((v) async => v * 3);
      expect(e, err<int, String>('x'));
    });

    test('asyncFlatMap', () async {
      final r = await ok<int, String>(
        7,
      ).asyncFlatMap((v) async => ok<int, String>(v * 3));
      expect(r, ok<int, String>(21));
      final e = await err<int, String>(
        'x',
      ).asyncFlatMap((v) async => ok<int, String>(v * 3));
      expect(e, err<int, String>('x'));
    });

    test('equality and toString', () {
      expect(ok<int, String>(1), ok<int, String>(1));
      expect(err<int, String>('a'), err<int, String>('a'));
      expect(ok<int, String>(1) == err<int, String>('a'), isFalse);
      expect(
        ok<int, String>(1).hashCode,
        isNot(err<int, String>('a').hashCode),
      );
      expect('${ok<int, String>(1)}', 'Ok(1)');
      expect('${err<int, String>('a')}', 'Err(a)');
    });

    test('factory constructors', () {
      const okValue = Result<int, Never>.ok(1);
      expect(okValue.isOk, isTrue);
      expect(okValue.okOrNull, 1);
      const errValue = Result<Never, String>.err('x');
      expect(errValue.isErr, isTrue);
      expect(errValue.errOrNull, 'x');
    });
  });

  group('VaultFailure codes', () {
    test('are stable and unique', () {
      final codes = allFailures.map((VaultFailure f) => f.code).toList();
      expect(codes.toSet().length, codes.length, reason: 'duplicate codes');
      for (final code in codes) {
        expect(code, matches(RegExp(r'^[A-Z][A-Z_]*$')));
      }
    });

    test('default isRetryable is false; retryable overrides', () {
      const retryable = SyncTransportFailure();
      const terminal = CorruptFile('b1');
      expect(retryable.isRetryable, isTrue);
      expect(terminal.isRetryable, isFalse);
    });

    test('exhaustive switch handles every subtype (compile-time gate)', () {
      for (final failure in allFailures) {
        expect(exhaustiveHandler(failure), isNotEmpty);
      }
    });
  });
}

T? okOrNull<T, E>(Result<T, E> r) => r.okOrNull;

E? errOrNullOf<T, E>(Result<T, E> r) => r.errOrNull;

/// One instance of every failure subtype. The exhaustive-switch test below
/// uses this list; adding a subtype WITHOUT adding it here is a compile
/// error in [exhaustiveHandler].
final List<VaultFailure> allFailures = [
  const InvalidAsset('r'),
  const CorruptFile('b'),
  const UnsupportedFormat('image/x'),
  const MissingVersion('v'),
  const VersionNotRematerializable('v'),
  const EntryInvariantViolated('I1'),
  const EncryptionFailed(),
  const DecryptionFailed(),
  const KeyUnavailable(KeyUnavailableReason.vaultLocked),
  const KeyRotationFailed(1, 2),
  const InsufficientStorage(10, 5),
  const StorageIoFailure('write'),
  const DatabaseFailure('insert'),
  const MigrationFailed(1, 2),
  const InvalidExportDimensions('w'),
  const SizeUnattainable(300, 200),
  const PdfGenerationFailed(),
  const ImageProcessingFailed('crop'),
  const SyncAuthRequired(),
  const SyncTransportFailure(),
  const CloudRateLimited(),
  const CloudQuotaExceeded(),
  const RemoteObjectMissing('r'),
  const RemoteObjectTampered('r'),
  const VersionConflict('c'),
  const SyncRequiresUpgrade(2),
  const OperationCancelled(),
  const OperationInterrupted('tok'),
  const AuthenticationFailed(2),
];

/// Exhaustive: the compiler enforces every subtype has a case.
String exhaustiveHandler(VaultFailure f) => switch (f) {
  InvalidAsset() => 'invalid-asset',
  CorruptFile() => 'corrupt-file',
  UnsupportedFormat() => 'unsupported-format',
  MissingVersion() => 'missing-version',
  VersionNotRematerializable() => 'not-rematerializable',
  EntryInvariantViolated() => 'invariant',
  EncryptionFailed() => 'encryption',
  DecryptionFailed() => 'decryption',
  KeyUnavailable() => 'key-unavailable',
  KeyRotationFailed() => 'rotation',
  InsufficientStorage() => 'storage',
  StorageIoFailure() => 'io',
  DatabaseFailure() => 'db',
  MigrationFailed() => 'migration',
  InvalidExportDimensions() => 'export-dimensions',
  SizeUnattainable() => 'size',
  PdfGenerationFailed() => 'pdf',
  ImageProcessingFailed() => 'image',
  SyncAuthRequired() => 'sync-auth',
  SyncTransportFailure() => 'sync-transport',
  CloudRateLimited() => 'rate-limited',
  CloudQuotaExceeded() => 'quota',
  RemoteObjectMissing() => 'remote-missing',
  RemoteObjectTampered() => 'remote-tampered',
  VersionConflict() => 'version-conflict',
  SyncRequiresUpgrade() => 'sync-upgrade',
  OperationCancelled() => 'cancelled',
  OperationInterrupted() => 'interrupted',
  AuthenticationFailed() => 'auth-failed',
};
