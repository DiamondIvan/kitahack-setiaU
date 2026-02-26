import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/calendar',
    ],
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

  /// Create a Google Calendar event from an action payload.
  /// Payload keys: eventName, date (YYYY-MM-DD), startTime (HH:mm or H:mm AM/PM),
  ///               endTime (HH:mm or H:mm AM/PM), description, attendees (`List<String>`).
  /// Returns the HTML link of the created event, or null on failure.
  static Future<String?> createCalendarEvent(
    Map<String, dynamic> payload,
  ) async {
    try {
      // Ensure signed in
      var account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('Google Calendar: user not signed in');
        return null;
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        debugPrint('Google Calendar: no access token');
        return null;
      }

      final date = payload['date'] as String? ?? '';
      final startTime = _parseTime(payload['startTime'] as String? ?? '00:00');
      final endTime = _parseTime(payload['endTime'] as String? ?? '01:00');

      if (date.isEmpty) {
        debugPrint('Google Calendar: missing date in payload');
        return null;
      }

      final attendeesList = (payload['attendees'] as List<dynamic>? ?? [])
          .map((e) => {'email': e.toString()})
          .toList();

      final body = jsonEncode({
        'summary': payload['eventName'] ?? 'New Event',
        'description': payload['description'] ?? '',
        'start': {
          'dateTime': '${date}T$startTime:00',
          'timeZone': 'Asia/Kuala_Lumpur',
        },
        'end': {
          'dateTime': '${date}T$endTime:00',
          'timeZone': 'Asia/Kuala_Lumpur',
        },
        if (attendeesList.isNotEmpty) 'attendees': attendeesList,
      });

      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final link = data['htmlLink'] as String? ?? '';
        debugPrint('Google Calendar event created: $link');
        return link;
      } else {
        debugPrint(
          'Google Calendar API error ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return null;
    }
  }

  /// Parses a time string that may be in 24-hour ("HH:mm") or
  /// 12-hour ("H:mm AM" / "H:mm PM") format and returns "HH:mm".
  static String _parseTime(String raw) {
    final trimmed = raw.trim();
    // 12-hour format
    final match12 = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match12 != null) {
      int hour = int.parse(match12.group(1)!);
      final minute = match12.group(2)!;
      final period = match12.group(3)!.toUpperCase();
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
      return '${hour.toString().padLeft(2, '0')}:$minute';
    }
    // 24-hour or already HH:mm
    final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!).toString().padLeft(2, '0');
      return '$hour:${match24.group(2)!}';
    }
    return '00:00'; // fallback
  }
}
