/// `GoogleDriveCloudProvider` over an in-memory Drive HTTP backend: the
/// REST mapping, upload idempotency, download, list, delete, quota, and
/// the §9.7 error classification. No Google account involved.
library;

import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_drive/vault_drive.dart';

/// A minimal in-memory Drive v3 backend: files keyed by id, upload via
/// multipart or resumable, list with `name contains` / `name =` filters,
/// alt=media download, delete, and scripted error responses.
final class FakeDriveBackend extends http.BaseClient {
  final Map<String, ({String name, List<int> bytes})> files = {};
  final List<int Function()> statusScript = [];
  int _nextId = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (statusScript.isNotEmpty) {
      final status = statusScript.removeAt(0)();
      return _json(status, {
        'error': {
          'code': status,
          'message': 'scripted',
          'errors': [
            {'reason': status == 403 ? 'userRateLimitExceeded' : 'backendError'},
          ],
        },
      });
    }
    final url = request.url;
    final path = url.path;
    if (request.method == 'POST' && path == '/upload/drive/v3/files') {
      if (url.queryParameters['uploadType'] == 'resumable') {
        final ticket = 'resume-${++_nextId}';
        files[ticket] = (name: '', bytes: []);
        return http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'location': 'https://upload.example/$ticket'},
        );
      }
      // multipart: metadata part + media part; we keep the whole body.
      final body = await request.finalize().toBytes();
      return _created(body, name: _nameFromMultipart(body));
    }
    if (request.method == 'PUT' && url.host == 'upload.example') {
      final ticket = url.pathSegments.last;
      files[ticket] = (
        name: '',
        bytes: await request.finalize().toBytes(),
      );
      return _created(files[ticket]!.bytes, name: 'resumed.bin');
    }
    if (request.method == 'GET' && path == '/drive/v3/files') {
      final q = url.queryParameters['q'] ?? '';
      final matched = [
        for (final entry in files.entries)
          if (entry.value.name.isNotEmpty && _matches(q, entry.value.name))
            _fileJson(entry.key, entry.value),
      ];
      return _json(200, {'files': matched});
    }
    if (request.method == 'GET' &&
        path.startsWith('/drive/v3/files/') &&
        url.queryParameters['alt'] == 'media') {
      final id = path.split('/').last;
      final file = files[id];
      if (file == null) {
        return _json(404, {'error': {'code': 404, 'message': 'not found'}});
      }
      return http.StreamedResponse(
        Stream.value(file.bytes),
        200,
        headers: {'content-type': 'application/octet-stream'},
      );
    }
    if (request.method == 'DELETE' && path.startsWith('/drive/v3/files/')) {
      final id = path.split('/').last;
      if (files.remove(id) == null) {
        return _json(404, {'error': {'code': 404, 'message': 'not found'}});
      }
      return http.StreamedResponse(Stream.value([]), 204);
    }
    if (request.method == 'GET' && path == '/drive/v3/about') {
      return _json(200, {
        'storageQuota': {'usage': '1024', 'limit': '15000'},
      });
    }
    return _json(404, {'error': {'code': 404, 'message': 'unhandled: $request'}});
  }

  http.StreamedResponse _created(List<int> bytes, {required String name}) {
    final id = 'file-${++_nextId}';
    files[id] = (name: name, bytes: bytes);
    return _json(200, _fileJson(id, files[id]!));
  }

  bool _matches(String q, String name) {
    final contains = RegExp("name contains '([^']*)'").firstMatch(q);
    if (contains != null) {
      return name.contains(contains[1]!);
    }
    final exact = RegExp("name = '([^']*)'").firstMatch(q);
    if (exact != null) {
      return name == exact[1]!;
    }
    return true;
  }

  Map<String, Object?> _fileJson(
    String id,
    ({String name, List<int> bytes}) file,
  ) => {
    'id': id,
    'name': file.name,
    'mimeType': 'application/octet-stream',
    'size': '${file.bytes.length}',
    'md5Checksum': 'md5-$id',
    'modifiedTime': '2026-01-01T00:00:00.000Z',
  };

  String _nameFromMultipart(List<int> body) {
    final text = utf8.decode(body, allowMalformed: true);
    final match = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(text);
    return match?[1] ?? 'uploaded.bin';
  }

  http.StreamedResponse _json(int status, Map<String, Object?> body) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

void main() {
  late FakeDriveBackend backend;
  late GoogleDriveCloudProvider provider;

  setUp(() {
    backend = FakeDriveBackend();
    final api = drive.DriveApi(backend);
    provider = GoogleDriveCloudProvider(apiFactory: () async => api);
  });

  test('authState is signedIn when the factory yields a client', () async {
    expect(
      (await provider.authState()).okOrNull,
      CloudAuthState.signedIn,
    );
  });

  test('put uploads ciphertext under the opaque name', () async {
    final result = await provider.put(
      'b_abc.bin',
      Stream.value([1, 2, 3, 4, 5]),
      totalBytes: 5,
      routingProps: const {'blobId': 'abc', 'envVer': '1'},
    );
    final remote = result.okOrNull!;
    expect(remote.remoteId, isNotNull);
    final stored = backend.files.values.single;
    expect(stored.name, 'b_abc.bin');
    // The upload body contains the ciphertext bytes (multipart framed).
    expect(utf8.decode(stored.bytes, allowMalformed: true), contains('blobId'));
  });

  test('put is idempotent by name: a retry is a no-op', () async {
    final first = (await provider.put('b_x.bin', Stream.value([1]), totalBytes: 1)).okOrNull!;
    final second = (await provider.put('b_x.bin', Stream.value([1]), totalBytes: 1)).okOrNull!;
    expect(second.remoteId, first.remoteId);
    expect(backend.files, hasLength(1));
  });

  test('get downloads the stored bytes', () async {
    final remote = (await provider.put('b_y.bin', Stream.value([9, 8, 7]), totalBytes: 3)).okOrNull!;
    final stream = (await provider.get(remote.remoteId)).okOrNull!;
    final bytes = <int>[];
    await stream.forEach(bytes.addAll);
    // The fake stores the multipart-framed upload; the payload travels
    // base64-encoded inside it ([9,8,7] → 'CQgH').
    expect(utf8.decode(bytes, allowMalformed: true), contains('CQgH'));
  });

  test('list filters by name prefix', () async {
    await provider.put('l_dev_0000001.bin', Stream.value([1]), totalBytes: 1);
    await provider.put('b_blob.bin', Stream.value([2]), totalBytes: 1);
    final logs = (await provider.list(namePrefix: 'l_')).okOrNull!;
    expect(logs.single.name, 'l_dev_0000001.bin');
  });

  test('delete removes the object; a second delete reports it missing', () async {
    final remote = (await provider.put('b_z.bin', Stream.value([1]), totalBytes: 1)).okOrNull!;
    expect((await provider.delete(remote.remoteId)).isOk, isTrue);
    final second = await provider.delete(remote.remoteId);
    expect(second.errOrNull, isA<RemoteObjectMissing>());
  });

  test('quota maps storageQuota', () async {
    final quota = (await provider.quota()).okOrNull!;
    expect(quota.usedBytes, 1024);
    expect(quota.limitBytes, 15000);
  });

  group('error classification (§9.7)', () {
    test('403 rate limit is CloudRateLimited', () async {
      backend.statusScript.add(() => 403);
      final result = await provider.list();
      expect(result.errOrNull, isA<CloudRateLimited>());
    });

    test('401 is SyncAuthRequired', () async {
      backend.statusScript.add(() => 401);
      final result = await provider.list();
      expect(result.errOrNull, isA<SyncAuthRequired>());
    });

    test('500 is SyncTransportFailure', () async {
      backend.statusScript.add(() => 500);
      final result = await provider.list();
      expect(result.errOrNull, isA<SyncTransportFailure>());
    });

    test('a missing factory client is SyncAuthRequired', () async {
      final empty = GoogleDriveCloudProvider(apiFactory: () async => null);
      final result = await empty.list();
      expect(result.errOrNull, isA<SyncAuthRequired>());
    });
  });
}
