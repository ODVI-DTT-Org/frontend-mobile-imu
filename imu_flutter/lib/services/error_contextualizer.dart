/// Error contextualizer for context-aware error messages
///
/// Provides user-friendly error messages based on the user's current action
class ErrorContextualizer {
  // Private constructor to prevent instantiation
  ErrorContextualizer._();

  /// Get contextual message based on error code and user action
  ///
  /// Combines error code with user action to provide more specific,
  /// context-aware error messages.
  ///
  /// Examples:
  /// - ("INVALID_CREDENTIALS", "login") → "Invalid email or password"
  /// - ("VALIDATION_ERROR", "save_client") → "Please check the client information"
  /// - ("CONFLICT", "submit_touchpoint") → "This touchpoint was already submitted"
  static String getContextualMessage(
    String errorCode,
    String userAction,
  ) {
    final key = '${userAction}_$errorCode';
    return _contextualMessages[key] ?? _getGenericContextualMessage(errorCode, userAction);
  }

  /// Get generic contextual message when no specific message exists
  static String _getGenericContextualMessage(String errorCode, String userAction) {
    // Get action description
    final actionDesc = _actionDescriptions[userAction] ?? 'complete this action';

    // Return generic message based on error type
    switch (errorCode) {
      case 'NETWORK_ERROR':
      case 'TIMEOUT':
      case 'CONNECTION_ERROR':
        return 'Unable to $actionDesc. Please check your connection.';

      case 'UNAUTHORIZED':
      case 'TOKEN_EXPIRED':
        return 'Please sign in to $actionDesc.';

      case 'FORBIDDEN':
      case 'INSUFFICIENT_PERMISSIONS':
        return 'You don\'t have permission to $actionDesc.';

      case 'VALIDATION_ERROR':
        return 'Please check your information to $actionDesc.';

      case 'NOT_FOUND':
        return 'The required information was not found to $actionDesc.';

      case 'CONFLICT':
        return 'Unable to $actionDesc due to a conflict.';

      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many attempts. Please wait before you try to $actionDesc.';

      default:
        return 'Unable to $actionDesc. Please try again.';
    }
  }

  // ==================== CONTEXTUAL MESSAGE MAPPINGS ====================

  // User action + error code → contextual message
  static const Map<String, String> _contextualMessages = {
    // Login action
    'login_INVALID_CREDENTIALS': 'Invalid email or password. Please try again.',
    'login_NETWORK_ERROR': 'Unable to sign in. Please check your internet connection.',
    'login_RATE_LIMIT_EXCEEDED': 'Too many sign in attempts. Please wait a moment.',
    'login_UNAUTHORIZED': 'Your account has been disabled. Please contact support.',

    // Register action
    'register_VALIDATION_ERROR': 'Please check your registration information.',
    'register_CONFLICT': 'An account with this email already exists.',
    'register_NETWORK_ERROR': 'Unable to create account. Please check your connection.',

    // Save client action
    'save_client_VALIDATION_ERROR': 'Please check the client information.',
    'save_client_NETWORK_ERROR': 'Unable to save client. Please check your connection.',
    'save_client_NOT_FOUND': 'Client not found. Unable to save changes.',
    'save_client_CLIENT_ALREADY_ASSIGNED': 'This client is already assigned to another agent.',

    // Delete client action
    'delete_client_NETWORK_ERROR': 'Unable to delete client. Please check your connection.',
    'delete_client_FORBIDDEN': 'You don\'t have permission to delete clients.',
    'delete_client_NOT_FOUND': 'Client not found. May have been already deleted.',

    // Submit touchpoint action
    'submit_touchpoint_VALIDATION_ERROR': 'Please check the touchpoint information.',
    'submit_touchpoint_INVALID_TOUCHPOINT_TYPE': 'You can only create visit touchpoints.',
    'submit_touchpoint_CONFLICT': 'This touchpoint was already submitted.',
    'submit_touchpoint_NETWORK_ERROR': 'Unable to submit touchpoint. Please check your connection.',
    'submit_touchpoint_FILE_TOO_LARGE': 'Photo or audio is too large. Maximum is 10MB.',

    // Save touchpoint (draft) action
    'save_touchpoint_VALIDATION_ERROR': 'Please check the touchpoint information.',
    'save_touchpoint_NETWORK_ERROR': 'Unable to save touchpoint. Please check your connection.',

    // Upload file action
    'upload_file_FILE_TOO_LARGE': 'File is too large. Maximum size is 10MB.',
    'upload_file_INVALID_FILE_TYPE': 'This file type is not supported.',
    'upload_file_NETWORK_ERROR': 'Unable to upload file. Please check your connection.',

    // Sync data action
    'sync_data_NETWORK_ERROR': 'Unable to sync. Please check your internet connection.',
    'sync_data_SYNC_FAILED': 'Sync failed. Please pull to refresh.',
    'sync_data_CONFLICT_DETECTED': 'Sync conflict detected. Server data will be used.',
    'sync_data_SYNC_IN_PROGRESS': 'Sync is in progress. Please wait.',

    // Create user action
    'create_user_VALIDATION_ERROR': 'Please check the user information.',
    'create_user_CONFLICT': 'A user with this email already exists.',
    'create_user_FORBIDDEN': 'You don\'t have permission to create users.',
    'create_user_NETWORK_ERROR': 'Unable to create user. Please check your connection.',

    // Assign territory action
    'assign_territory_VALIDATION_ERROR': 'Please check the territory information.',
    'assign_territory_FORBIDDEN': 'You don\'t have permission to assign territories.',
    'assign_territory_NETWORK_ERROR': 'Unable to assign territory. Please check your connection.',

    // Update profile action
    'update_profile_VALIDATION_ERROR': 'Please check your profile information.',
    'update_profile_PASSWORD_TOO_WEAK': 'New password is too weak.',
    'update_profile_NETWORK_ERROR': 'Unable to update profile. Please check your connection.',

    // Change password action
    'change_password_VALIDATION_ERROR': 'Please check your password information.',
    'change_password_PASSWORD_TOO_WEAK': 'New password is too weak.',
    'change_password_INVALID_CREDENTIALS': 'Current password is incorrect.',
  };

  // User action to description mapping
  static const Map<String, String> _actionDescriptions = {
    'login': 'sign in',
    'register': 'create your account',
    'save_client': 'save the client',
    'delete_client': 'delete the client',
    'submit_touchpoint': 'submit the touchpoint',
    'save_touchpoint': 'save the touchpoint',
    'upload_file': 'upload the file',
    'sync_data': 'sync your data',
    'create_user': 'create the user',
    'assign_territory': 'assign the territory',
    'update_profile': 'update your profile',
    'change_password': 'change your password',
  };
}
