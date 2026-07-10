import 'dart:convert';

/// Lightweight in-memory store for vendor registration data.
///
/// Stores the submitted JSON so it can be read back from anywhere in the app
/// during the session.  In a real implementation this would write to a backend
/// or local SQLite/file via path_provider, but for the dummy-data phase the
/// static fields are sufficient.
class VendorDataStore {
  VendorDataStore._();

  /// Last saved registration payload (read-only copy).
  static Map<String, dynamic>? _lastRegistration;

  /// Pretty-printed JSON of the last saved registration.
  static String? _lastRegistrationJson;

  static Map<String, dynamic>? get lastRegistration => _lastRegistration;
  static String? get lastRegistrationJson => _lastRegistrationJson;

  /// Persist vendor registration data.
  ///
  /// Serialises [data] to JSON, stores it in memory and (in debug mode)
  /// keeps it in memory for quick inspection during the current session.
  static Future<void> saveRegistration(Map<String, dynamic> data) async {
    _lastRegistration = Map<String, dynamic>.unmodifiable(data);
    _lastRegistrationJson = const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Clear the in-memory store (useful for testing).
  static void clear() {
    _lastRegistration = null;
    _lastRegistrationJson = null;
  }
}
