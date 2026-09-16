/// Google sign-in for the `drive.appdata` scope (§9.2, §15.4).
///
/// The scope is the sensitive one: production use needs Google's OAuth
/// app verification (R4) — started in Phase 0, not here. Tokens come from
/// `google_sign_in` per call, so expiry is Google's problem, not ours.
library;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

final class GoogleDriveAuth {
  GoogleDriveAuth({GoogleSignIn? signIn})
    : _signIn =
          signIn ??
          GoogleSignIn(
            scopes: const ['https://www.googleapis.com/auth/drive.appdata'],
          );

  static const scope = 'https://www.googleapis.com/auth/drive.appdata';

  final GoogleSignIn _signIn;

  /// The current account, or null when signed out.
  Future<GoogleSignInAccount?> account() => _signIn.signInSilently();

  /// Interactive sign-in (user tapped "Connect Google Drive").
  Future<GoogleSignInAccount?> signIn() => _signIn.signIn();

  Future<void> signOut() => _signIn.signOut();

  /// A Drive API client for the signed-in account, or null when no
  /// account is available without interaction.
  Future<drive.DriveApi?> api({bool interactive = false}) async {
    final account =
        await _signIn.signInSilently() ??
        (interactive ? await _signIn.signIn() : null);
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) {
      return null;
    }
    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        token,
        // A far-future placeholder: the real refresh path is
        // google_sign_in's `authentication` per call (§13.2: no wall
        // clock outside the composition root).
        DateTime.utc(2099),
      ),
      null, // google_sign_in refreshes on demand; no refresh token here
      const [scope],
    );
    return drive.DriveApi(authenticatedClient(http.Client(), credentials));
  }
}
