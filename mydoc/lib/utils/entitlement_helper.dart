/// Reads the response of GET /plans/entitlement/{doctor_id}, e.g.
/// {
///   "id": "a8ead6e0-...",
///   "plan": {"id": "...", "name": "TRIAL", "price": 0, ...},
///   "allocated_seconds": 1000000,
///   "consumed_seconds": 0,
///   "reserved_seconds": 0,
///   "starts_at": "01-Oct-2026 06:49",
///   "expires_at": "31-Oct-2026 06:49",
///   "remaining_seconds": 1000000
/// }
///
/// When the doctor has no entitlement the backend returns something like
/// {custom_status: 404, message: No data available, data: []}.
class EntitlementHelper {
  /// Returns the entitlement map, or null if the response is not a map.
  static Map<String, dynamic>? unwrap(dynamic raw) {
    if (raw is! Map) return null;

    final dynamic data =
        raw.containsKey('response') ? raw['response'] : raw;

    if (data is! Map) return null;

    return Map<String, dynamic>.from(data);
  }

  /// Parses dates like "31-Oct-2026 06:49".
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final text = value.toString().trim();

    final match = RegExp(
      r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(text);

    if (match == null) return DateTime.tryParse(text);

    final month = months[match.group(2)!.toLowerCase()];
    if (month == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4) ?? '23'),
      int.parse(match.group(5) ?? '59'),
    );
  }

  /// True if the doctor has an entitlement that has not expired.
  static bool isEnrolled(dynamic raw) {
    final data = unwrap(raw);

    if (data == null) return false;

    // "No data available" response
    if (data['custom_status'] == 404) return false;

    // A real entitlement always has an id
    if (data['id'] == null) return false;

    final expiry = parseDate(data['expires_at']);
    if (expiry != null && expiry.isBefore(DateTime.now())) return false;

    return true;
  }

  /// Seconds left in the plan (0 if unknown).
  static int remainingSeconds(dynamic raw) {
    final data = unwrap(raw);
    final value = data?['remaining_seconds'];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
