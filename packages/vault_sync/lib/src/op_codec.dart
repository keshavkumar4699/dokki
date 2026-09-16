/// Segment payload codec (§9.3, §9.6).
///
/// A sealed segment's plaintext is UTF-8 JSONL:
/// line 1 is the header `{segmentVersion, minReaderVersion, deviceId,
/// seq}`; each following line is one `SyncOp` in canonical JSON form
/// (named fields, never positional — §9.6 rule 2).
///
/// The codec is deliberately small and pure so a CBOR variant can replace
/// it without the engine noticing.
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';

/// The segment format this build writes.
const int segmentFormatVersion = 1;

final class SegmentPayload {
  const SegmentPayload({
    required this.deviceId,
    required this.seq,
    required this.ops,
  });

  final DeviceId deviceId;
  final int seq;
  final List<SyncOp> ops;
}

String encodeSegmentPayload({
  required DeviceId deviceId,
  required int seq,
  required List<SyncOp> ops,
}) {
  final buffer = StringBuffer()
    ..writeln(
      jsonEncode({
        'segmentVersion': segmentFormatVersion,
        'minReaderVersion': 1,
        'deviceId': deviceId,
        'seq': seq,
      }),
    );
  for (final op in ops) {
    buffer.writeln(encodeSyncOp(op));
  }
  return buffer.toString();
}

/// Parses a segment. Throws [SegmentRequiresUpgrade] when the writer's
/// `minReaderVersion` is newer than this build understands (§9.6 rule 5).
SegmentPayload decodeSegmentPayload(String payload) {
  final lines = const LineSplitter().convert(payload);
  if (lines.isEmpty) {
    throw const FormatException('empty segment payload');
  }
  final header = (jsonDecode(lines.first) as Map<Object?, Object?>)
      .cast<String, Object?>();
  final minReader = (header['minReaderVersion'] as num?)?.toInt() ?? 1;
  if (minReader > currentOpSchemaVersion) {
    throw SegmentRequiresUpgrade(minReader);
  }
  final ops = <SyncOp>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) {
      continue;
    }
    final json = (jsonDecode(line) as Map<Object?, Object?>)
        .cast<String, Object?>();
    ops.add(_lenientOp(json));
  }
  return SegmentPayload(
    deviceId: header['deviceId']! as String,
    seq: (header['seq']! as num).toInt(),
    ops: ops,
  );
}

/// Unknown op types are preserved verbatim and skipped, never dropped
/// (§9.6 rule 3); unknown FIELDS are ignored by the op parsers, which is
/// what makes them forward-compatible.
SyncOp _lenientOp(Map<String, Object?> json) {
  try {
    return SyncOp.fromJson(json);
  } on FormatException {
    return UnknownSyncOp(
      hlc: Hlc.parse(json['hlc']! as String),
      origin: json['origin']! as String,
      opSchemaVersion: (json['opSchemaVersion'] as num?)?.toInt() ?? 0,
      rawJson: json,
    );
  }
}
