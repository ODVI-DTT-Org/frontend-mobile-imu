/// User roles for the IMU mobile app.
///
/// Mobile app supports: Admin, Area Manager, Assistant Area Manager, Caravan.
/// Tele users use the web admin dashboard.
enum UserRole {
  /// Full system access
  admin('admin'),

  /// Can manage assigned area and create all touchpoint types
  areaManager('area_manager'),

  /// Can manage assigned area and create all touchpoint types
  assistantAreaManager('assistant_area_manager'),

  /// Field agent - can only create Visit touchpoints (1, 4, 7)
  caravan('caravan');

  final String _apiValue;
  const UserRole(this._apiValue);

  /// API value for serialization
  String get apiValue => _apiValue;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.areaManager:
        return 'Area Manager';
      case UserRole.assistantAreaManager:
        return 'Assistant Area Manager';
      case UserRole.caravan:
        return 'Caravan';
    }
  }

  /// Can this role create any touchpoint type (Visit OR Call)?
  bool get canCreateAnyTouchpoint {
    return isManager;
  }

  /// Can this role create Visit touchpoints?
  /// All mobile roles can create visits.
  bool get canCreateVisitTouchpoints => true;

  /// Can this role create Call touchpoints?
  /// Only managers can create calls.
  bool get canCreateCallTouchpoints => canCreateAnyTouchpoint;

  /// Is this a manager role with elevated permissions?
  bool get isManager {
    switch (this) {
      case UserRole.admin:
      case UserRole.areaManager:
      case UserRole.assistantAreaManager:
        return true;
      case UserRole.caravan:
        return false;
    }
  }

  /// Parse UserRole from backend API response.
  ///
  /// Handles legacy role mapping for backward compatibility:
  /// - 'field_agent', 'fieldAgent', 'staff' → caravan
  /// - null, empty, unknown → caravan (safe default)
  static UserRole fromApi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UserRole.caravan;
    }

    final normalized = _normalizeLegacyRole(value.trim());

    try {
      return UserRole.values.firstWhere(
        (role) => role.apiValue == normalized,
        orElse: () => UserRole.caravan,
      );
    } catch (e) {
      // Safe fallback for unknown roles
      return UserRole.caravan;
    }
  }

  /// Parse UserRole from JWT token.
  ///
  /// Handles legacy role mapping for backward compatibility.
  static UserRole fromJwt(Map<String, dynamic> jwt) {
    final roleString = jwt['role'] as String?;

    if (roleString == null || roleString.trim().isEmpty) {
      return UserRole.caravan;
    }

    final normalized = _normalizeLegacyRole(roleString.trim());

    try {
      return UserRole.values.firstWhere(
        (role) => role.apiValue == normalized,
        orElse: () => UserRole.caravan,
      );
    } catch (e) {
      // Safe fallback for unknown roles
      return UserRole.caravan;
    }
  }

  /// Normalize legacy role names to current format.
  static String _normalizeLegacyRole(String role) {
    final legacyMap = <String, String>{
      'field_agent': 'caravan',
      'staff': 'caravan',
      'fieldagent': 'caravan',
    };

    final normalized = legacyMap[role.toLowerCase()];
    return normalized ?? role.toLowerCase();
  }
}
