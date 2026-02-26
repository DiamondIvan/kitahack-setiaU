import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/calendar',
    ],
    // Server client ID (Web OAuth client) for token verification on Android
    serverClientId: '253733137049-jaj0mipf1gll7j52f4bq3hisnbqie1ll.apps.googleusercontent.com',
  );

  /// Sign in with Google and get calendar access
  static Future<GoogleSignInAccount?> signInForCalendar() async {
    try {
      final account = await _googleSignIn.signIn();
      debugPrint('Google Sign In successful: ${account?.email}');
      return account;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      return null;
    }
  }

  /// Get the current signed-in account
  static Future<GoogleSignInAccount?> getCurrentAccount() async {
    return await _googleSignIn.signInSilently();
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get access token for the signed-in account
  static Future<String?> getAccessToken() async {
    try {
      final account = await getCurrentAccount();
      if (account == null) {
        debugPrint('No Google account signed in');
        return null;
      }

      final auth = await account.authentication;
      debugPrint('Got access token for ${account.email}');
      return auth.accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  /// Check if user is already signed in
  static Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }
}
