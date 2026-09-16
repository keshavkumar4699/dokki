import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';

void main() {
  test('SensitiveValue never reveals its payload in toString', () {
    const secret = SensitiveValue<String>('hunter2');
    expect('$secret', '***');
    expect(secret.toString(), '***');

    const bytes = SensitiveBytes([0, 1, 2, 3]);
    expect(bytes.toString(), '***');
  });

  test('SensitiveValue still compares by payload', () {
    expect(
      const SensitiveValue<String>('a'),
      const SensitiveValue<String>('a'),
    );
    expect(
      const SensitiveValue<String>('a'),
      isNot(const SensitiveValue<String>('b')),
    );
  });

  test('works in string interpolation and error paths', () {
    const title = SensitiveValue<String>('Passport - Renewal 2027');
    final message = 'failed to load $title';
    expect(message, isNot(contains('Passport')));
  });

  test('VaultLog routes everything through the sink and redacts', () {
    final lines = <(VaultLogLevel, String)>[];
    VaultLog(sink: _TestSink(lines), debugEnabled: true)
      ..d('debug line')
      ..i('info line')
      ..w('warning line')
      ..e('error line', failureCode: 'CORRUPT_FILE');

    expect(lines, hasLength(4));
    expect(lines.first.$1, VaultLogLevel.debug);
    expect(lines.last.$2, contains('CORRUPT_FILE'));
  });

  test('VaultLog drops debug lines when disabled', () {
    final lines = <(VaultLogLevel, String)>[];
    VaultLog(sink: _TestSink(lines), debugEnabled: false)
      ..d('nope')
      ..i('kept');
    expect(lines, hasLength(1));
    expect(lines.single.$1, VaultLogLevel.info);
  });

  test('failure codes are the only failure detail logged', () {
    final lines = <(VaultLogLevel, String)>[];
    VaultLog(
      sink: _TestSink(lines),
      debugEnabled: true,
    ).e('read failed', failureCode: 'DECRYPTION_FAILED');
    expect(lines.single.$2, 'read failed [DECRYPTION_FAILED]');
  });
}

final class _TestSink implements VaultLogSink {
  _TestSink(this.lines);

  final List<(VaultLogLevel, String)> lines;

  @override
  void write(VaultLogLevel level, String message) {
    lines.add((level, message));
  }
}
