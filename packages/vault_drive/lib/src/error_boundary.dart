/// The ONE translation boundary of `vault_drive` (§12.3, §9.7 error
/// classification).
library;

import 'dart:async';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' show DetailedApiRequestError;
import 'package:googleapis_auth/googleapis_auth.dart'
    show AccessDeniedException;
import 'package:http/http.dart' as http;
import 'package:vault_domain/vault_domain.dart';

/// Raised when no signed-in account can produce a client without user
/// interaction (§9.7: surface, stop).
final class DriveNotAuthorized implements Exception {
  const DriveNotAuthorized();
}

/// Runs a Drive call, classifying failures per §9.7:
///
/// | condition                    | class        | meaning upstream |
/// |---|---|---|
/// | 403 rate limit / 429         | throttled    | back off, pause queue |
/// | 5xx / socket errors          | transient    | retry with jitter |
/// | 401 / access denied          | auth         | surface, stop |
/// | 403 storageQuotaExceeded     | terminal-ish | stop uploads |
/// | 404                          | remote gone  | mark MISSING |
Future<Result<T, VaultFailure>> guardDrive<T>(
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on DriveNotAuthorized catch (e, s) {
    return Err(SyncAuthRequired(cause: e, trace: s));
  } on DetailedApiRequestError catch (e, s) {
    return Err(_classify(e, s));
  } on AccessDeniedException catch (e, s) {
    return Err(CloudRateLimited(cause: e, trace: s));
  } on SocketException catch (e, s) {
    return Err(SyncTransportFailure(cause: e, trace: s));
  } on http.ClientException catch (e, s) {
    return Err(SyncTransportFailure(cause: e, trace: s));
  } on TimeoutException catch (e, s) {
    return Err(SyncTransportFailure(cause: e, trace: s));
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  }
}

VaultFailure _classify(DetailedApiRequestError e, StackTrace s) {
  final status = e.status;
  final reason = e.errors.firstOrNull?.reason ?? '';
  if (status == 401) {
    return SyncAuthRequired(cause: e, trace: s);
  }
  if (status == 403 && reason == 'storageQuotaExceeded') {
    return CloudQuotaExceeded(cause: e, trace: s);
  }
  if (status == 403 || status == 429) {
    // userRateLimitExceeded / rateLimitExceeded / plain 429.
    return CloudRateLimited(cause: e, trace: s);
  }
  if (status == 404) {
    return RemoteObjectMissing('', cause: e, trace: s);
  }
  if (status != null && status >= 500) {
    return SyncTransportFailure(httpStatus: status, cause: e, trace: s);
  }
  return SyncTransportFailure(httpStatus: status, cause: e, trace: s);
}
