import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/logger.dart';

abstract class GoogleAuthDataSource {
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      // Get the Web Client ID from environment (required for Android backend auth)
      // Note: Even on Android, we need the WEB client ID for serverClientId
      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID_WEB'];

      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
      _initialized = true;
    }
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();

      // Check if authenticate is supported (not supported on web)
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();
        return googleUser;
      } else {
        // On web, authentication must be done via renderButton widget
        throw UnsupportedError(
          'Google Sign-In on web requires using the GoogleSignInButton widget. '
          'Please use the web-specific sign-in button.',
        );
      }
    } catch (e) {
      AppLogger.error('Google Sign-In error', e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
  }
}
