/// Utility class for safe DateTime parsing
///
/// Handles various datetime formats that may come from:
/// - PostgreSQL timestamps
/// - ISO 8601 strings
/// - Legacy date formats
class DateUtils {
  /// Safely parse a DateTime from a dynamic value
  ///
  /// Returns null if parsing fails or value is null
  static DateTime? safeParse(dynamic value) {
    if (value == null) return null;

    try {
      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        // Handle empty strings
        if (value.trim().isEmpty) return null;

        // Try ISO 8601 format first (most common)
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Continue to other formats
        }

        // Try PostgreSQL timestamp format: YYYY-MM-DD HH:MM:SS
        if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}').hasMatch(value)) {
          return DateTime.parse('${value}Z');
        }

        // Try date only format: YYYY-MM-DD
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
          return DateTime.parse('${value}T00:00:00Z');
        }

        // Unable to parse - silent failure for non-Flutter environments
        return null;
      }

      if (value is int) {
        // Unix timestamp in seconds
        if (value > 1000000000000) {
          // Milliseconds
          return DateTime.fromMillisecondsSinceEpoch(value);
        } else {
          // Seconds
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        }
      }

      // Unsupported type - silent failure
      return null;
    } catch (e) {
      // Error parsing - silent failure for non-Flutter environments
      return null;
    }
  }

  /// Safely parse a DateTime from a dynamic value, with fallback
  ///
  /// Returns [fallback] if parsing fails or value is null
  static DateTime safeParseWithFallback(dynamic value, DateTime fallback) {
    return safeParse(value) ?? fallback;
  }

  /// Format DateTime for API requests
  ///
  /// Always returns ISO 8601 format or null
  static String? toIso8601String(DateTime? dateTime) {
    if (dateTime == null) return null;
    try {
      return dateTime.toIso8601String();
    } catch (e) {
      // Error formatting - return null silently
      return null;
    }
  }

  /// Validate if a date string is in a valid format
  static bool isValidDateString(String? dateString) {
    if (dateString == null || dateString.trim().isEmpty) return false;
    return safeParse(dateString) != null;
  }

  /// Get current UTC time as ISO 8601 string
  static String nowAsIso8601String() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Calculate the difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if a date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if a date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}
