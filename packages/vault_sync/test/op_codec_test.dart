/// Segment payload codec tests (§9.6): round-trip fidelity, unknown-op
/// preservation, and the minReaderVersion halt.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_sync/vault_sync.dart';

import 'support/fakes.dart';

void main() {
  final hlc = hlcAt(1000, 0, 'device-a');

  SyncOp entry(String id, int ms) => UpsertEntryOp(
    hlc: hlcAt(ms, 0, 'device-a'),
    origin: 'device-a',
    id: id,
    type: 'PHOTO',
    sealedTitleBase64: sealedField('Passport'),
    sealedNoteBase64: null,
    sealedTagsBase64: null,
    createdAtMillis: ms,
    deletedAtMillis: null,
  );

  test('a payload round-trips header and ops in order', () {
    final ops = [entry('e1', 1000), entry('e2', 2000)];
    final payload = encodeSegmentPayload(
      deviceId: 'device-a',
      seq: 7,
      ops: ops,
    );
    final decoded = decodeSegmentPayload(payload);
    expect(decoded.deviceId, 'device-a');
    expect(decoded.seq, 7);
    expect(decoded.ops, hasLength(2));
    final first = decoded.ops.first as UpsertEntryOp;
    expect(first.id, 'e1');
    expect(first.hlc, hlcAt(1000, 0, 'device-a'));
    expect(
      utf8.decode(base64Decode(first.sealedTitleBase64!)),
      'Passport',
    );
  });

  test('an unknown op type is preserved, never dropped (§9.6 rule 3)', () {
    final futureOp = jsonEncode({
      'op': 'shareEntry',
      'hlc': hlc.toSortableString(),
      'origin': 'device-a',
      'opSchemaVersion': 9,
      'id': 'e9',
      'recipient': 'someone@example.com',
    });
    final payload =
        '${jsonEncode({
          'segmentVersion': 1,
          'minReaderVersion': 1,
          'deviceId': 'device-a',
          'seq': 1,
        })}\n$futureOp\n';
    final decoded = decodeSegmentPayload(payload);
    expect(decoded.ops.single, isA<UnknownSyncOp>());
    final unknown = decoded.ops.single as UnknownSyncOp;
    expect(unknown.rawJson['recipient'], 'someone@example.com');
    expect(unknown.opSchemaVersion, 9);
  });

  test('a newer minReaderVersion halts with SegmentRequiresUpgrade', () {
    final payload = jsonEncode({
      'segmentVersion': 1,
      'minReaderVersion': 99,
      'deviceId': 'device-a',
      'seq': 1,
    });
    expect(
      () => decodeSegmentPayload(payload),
      throwsA(
        isA<SegmentRequiresUpgrade>().having(
          (e) => e.minReaderVersion,
          'minReaderVersion',
          99,
        ),
      ),
    );
  });

  test('unknown fields on known ops are ignored (rule 4)', () {
    final opJson = jsonEncode({
      'op': 'upsertEntry',
      'hlc': hlc.toSortableString(),
      'origin': 'device-a',
      'opSchemaVersion': 2,
      'id': 'e1',
      'type': 'PHOTO',
      'sealedTitleBase64': null,
      'sealedNoteBase64': null,
      'sealedTagsBase64': null,
      'createdAtMillis': 1000,
      'deletedAtMillis': null,
      'futureField': {'nested': true},
    });
    final payload =
        '${jsonEncode({
          'segmentVersion': 1,
          'minReaderVersion': 1,
          'deviceId': 'device-a',
          'seq': 1,
        })}\n$opJson\n';
    final decoded = decodeSegmentPayload(payload);
    expect(decoded.ops.single, isA<UpsertEntryOp>());
  });
}
