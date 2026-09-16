/// `GoogleDriveCloudProvider` (§9.1, §9.2): the ONLY class in the
/// workspace that knows Google Drive exists.
///
/// Everything lives in `appDataFolder` (`drive.appdata` scope): invisible
/// to the user's Drive UI, minimal privilege. Names are opaque
/// (`b_<uuid>.bin`, `l_<dev>_<seq>.bin`); `appProperties` carry routing
/// metadata only and are treated as public (M11).
library;

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';

/// Builds the API client on demand (auth lives behind this seam so tests
/// can inject a Drive over a fake HTTP backend).
typedef DriveApiFactory = Future<drive.DriveApi?> Function();

final class GoogleDriveCloudProvider implements CloudProvider {
  GoogleDriveCloudProvider({required DriveApiFactory apiFactory})
    : _apiFactory = apiFactory;

  final DriveApiFactory _apiFactory;

  static const _mime = 'application/octet-stream';
  static const _folder = 'appDataFolder';
  static const _fileFields = 'id,name,size,md5Checksum,modifiedTime';

  @override
  String get providerId => 'google_drive';

  Future<drive.DriveApi> _api() async {
    final api = await _apiFactory();
    if (api == null) {
      throw const DriveNotAuthorized();
    }
    return api;
  }

  @override
  Future<Result<CloudAuthState, VaultFailure>> authState() =>
      guardDrive(() async {
        await _api();
        return CloudAuthState.signedIn;
      });

  @override
  Future<Result<void, VaultFailure>> ensureAuthorized() =>
      guardDrive(() async {
        await _api();
      });

  @override
  Future<Result<RemoteObject, VaultFailure>> put(
    String opaqueName,
    Stream<List<int>> ciphertext, {
    required int totalBytes,
    Map<String, String> routingProps = const {},
    String? resumeToken,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardDrive(() async {
    final api = await _api();
    // Idempotent by name (§9.3): a retry of the same upload is a no-op.
    final existing = await _findByName(api, opaqueName);
    if (existing != null) {
      return existing;
    }
    final counted = ciphertext.map((chunk) {
      cancel?.throwIfCancelled();
      progress?.call(0, totalBytes);
      return chunk;
    });
    final created = await api.files.create(
      drive.File(
        name: opaqueName,
        parents: const [_folder],
        mimeType: _mime,
        appProperties: routingProps,
      ),
      uploadMedia: drive.Media(counted, totalBytes),
      $fields: _fileFields,
    );
    return RemoteObject(
      remoteId: created.id!,
      name: created.name ?? opaqueName,
      sizeBytes: int.tryParse(created.size ?? ''),
      checksum: created.md5Checksum,
      modifiedAt: created.modifiedTime,
    );
  });

  @override
  Future<Result<Stream<List<int>>, VaultFailure>> get(
    String remoteId, {
    ByteRange? range,
  }) => guardDrive(() async {
    final api = await _api();
    final media =
        await api.files.get(
              remoteId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    return media.stream;
  });

  @override
  Future<Result<List<RemoteObject>, VaultFailure>> list({
    String? namePrefix,
    String? pageToken,
  }) => guardDrive(() async {
    final api = await _api();
    final query = StringBuffer('trashed = false');
    if (namePrefix != null && namePrefix.isNotEmpty) {
      query.write(" and name contains '${_escape(namePrefix)}'");
    }
    final result = await api.files.list(
      spaces: _folder,
      q: query.toString(),
      pageSize: 1000,
      pageToken: pageToken,
      $fields: 'files($_fileFields),nextPageToken',
    );
    return [
      for (final file in result.files ?? const <drive.File>[])
        RemoteObject(
          remoteId: file.id!,
          name: file.name ?? '',
          sizeBytes: int.tryParse(file.size ?? ''),
          checksum: file.md5Checksum,
          modifiedAt: file.modifiedTime,
        ),
    ];
  });

  @override
  Future<Result<void, VaultFailure>> delete(String remoteId) =>
      guardDrive(() async {
        final api = await _api();
        await api.files.delete(remoteId);
      });

  @override
  Future<Result<CloudQuota, VaultFailure>> quota() => guardDrive(() async {
    final api = await _api();
    final about = await api.about.get($fields: 'storageQuota');
    return CloudQuota(
      usedBytes: int.tryParse(about.storageQuota?.usage ?? ''),
      limitBytes: int.tryParse(about.storageQuota?.limit ?? ''),
    );
  });

  /// Name-keyed lookup for upload idempotency (§9.3).
  Future<RemoteObject?> _findByName(
    drive.DriveApi api,
    String name,
  ) async {
    final result = await api.files.list(
      spaces: _folder,
      q: "trashed = false and name = '${_escape(name)}'",
      pageSize: 1,
      $fields: 'files($_fileFields)',
    );
    final file = result.files?.firstOrNull;
    if (file == null) {
      return null;
    }
    return RemoteObject(
      remoteId: file.id!,
      name: file.name ?? name,
      sizeBytes: int.tryParse(file.size ?? ''),
      checksum: file.md5Checksum,
      modifiedAt: file.modifiedTime,
    );
  }

  static String _escape(String value) => value.replaceAll("'", r"\'");
}
