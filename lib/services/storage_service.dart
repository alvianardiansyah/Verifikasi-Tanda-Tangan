import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _identificationHistoryKey = 'identification_history';
  static const String _verificationHistoryKey = 'verification_history';
  static const String _serverUrlKey = 'server_url';
  static const String _themePreferenceKey = 'theme_preference';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Save identification result to history
  static Future<void> saveIdentificationResult(
    Map<String, dynamic> result,
  ) async {
    final prefs = await _prefs;
    final List<String> history =
        prefs.getStringList(_identificationHistoryKey) ?? [];

    // Add timestamp to result
    final resultWithTimestamp = {
      ...result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.add(json.encode(resultWithTimestamp));

    // Keep only last 50 results
    if (history.length > 50) {
      history.removeAt(0);
    }

    await prefs.setStringList(_identificationHistoryKey, history);
  }

  // Get identification history
  static Future<List<Map<String, dynamic>>> getIdentificationHistory() async {
    final prefs = await _prefs;
    final List<String> history =
        prefs.getStringList(_identificationHistoryKey) ?? [];

    return history
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList()
        .reversed // Show latest first
        .toList();
  }

  // Save verification result to history
  static Future<void> saveVerificationResult(
    Map<String, dynamic> result,
  ) async {
    final prefs = await _prefs;
    final List<String> history =
        prefs.getStringList(_verificationHistoryKey) ?? [];

    // Add timestamp to result
    final resultWithTimestamp = {
      ...result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.add(json.encode(resultWithTimestamp));

    // Keep only last 50 results
    if (history.length > 50) {
      history.removeAt(0);
    }

    await prefs.setStringList(_verificationHistoryKey, history);
  }

  // Get verification history
  static Future<List<Map<String, dynamic>>> getVerificationHistory() async {
    final prefs = await _prefs;
    final List<String> history =
        prefs.getStringList(_verificationHistoryKey) ?? [];

    return history
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList()
        .reversed // Show latest first
        .toList();
  }

  // Theme Preferences
  static Future<void> saveThemePreference(String theme) async {
    final prefs = await _prefs;
    await prefs.setString(_themePreferenceKey, theme);
  }

  static Future<String> getThemePreference() async {
    final prefs = await _prefs;
    return prefs.getString(_themePreferenceKey) ?? 'system';
  }

  // Clear all history
  static Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_identificationHistoryKey);
    await prefs.remove(_verificationHistoryKey);
  }

  // Clear specific history
  static Future<void> clearIdentificationHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_identificationHistoryKey);
  }

  static Future<void> clearVerificationHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_verificationHistoryKey);
  }
}
