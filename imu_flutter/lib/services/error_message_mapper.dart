import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Centralized mapper for converting technical error codes to user-friendly messages
///
/// Maps error codes from the backend API to human-readable titles, messages,
/// suggestions, icons, and colors for display in the UI.
class ErrorMessageMapper {
  // Private constructor to prevent instantiation
  ErrorMessageMapper._();

  /// Get user-friendly title for error code
  static String getTitle(String errorCode) {
    return _errorTitles[errorCode] ?? 'Error';
  }

  /// Get user-friendly message for error code
  static String getMessage(String errorCode, {Map<String, dynamic>? details}) {
    final message = _errorMessages[errorCode];
    if (message != null) {
      return message;
    }

    // Fallback for unknown errors
    if (details != null && details.containsKey('message')) {
      final rawMessage = details['message'] as String?;
      if (rawMessage != null && rawMessage.isNotEmpty) {
        return _simplifyTechnicalMessage(rawMessage);
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get actionable suggestions for error code
  static List<String> getSuggestions(String errorCode) {
    return _errorSuggestions[errorCode] ?? [];
  }

  /// Get icon for error code
  static IconData getIcon(String errorCode) {
    return _errorIcons[errorCode] ?? LucideIcons.alertCircle;
  }

  /// Get color for error code
  static Color getColor(String errorCode) {
    return _errorColors[errorCode] ?? Colors.red;
  }

  /// Simplify technical error messages
  static String _simplifyTechnicalMessage(String message) {
    // Remove common technical prefixes
    String simplified = message
        .replaceFirst(RegExp(r'^[A-Z_]+:\s*'), '') // Remove "ERROR_CODE: " prefix
        .replaceFirst(RegExp(r'^\w+\.\w+:\s*'), '') // Remove "Class.method: " prefix
        .replaceAll(RegExp(r'\b(HttpException|SocketException|FormatException)\b:*'), '')
        .replaceAll(RegExp(r'\b\d{3}\s*(?!\d)'), '') // Remove HTTP status codes
        .trim();

    return simplified.isEmpty ? 'An error occurred. Please try again.' : simplified;
  }

  // ==================== ERROR CODE MAPPINGS ====================

  // Error code to user-friendly title mapping
  static const Map<String, String> _errorTitles = {
    // Authentication Errors
    'INVALID_CREDENTIALS': 'Sign In Failed',
    'TOKEN_EXPIRED': 'Session Expired',
    'TOKEN_INVALID': 'Authentication Error',
    'UNAUTHORIZED': 'Sign In Required',

    // Permission Errors
    'FORBIDDEN': 'Access Denied',
    'INSUFFICIENT_PERMISSIONS': 'Limited Access',

    // Validation Errors
    'VALIDATION_ERROR': 'Invalid Information',
    'INVALID_INPUT': 'Invalid Input',
    'INVALID_EMAIL': 'Invalid Email',
    'INVALID_PHONE': 'Invalid Phone Number',
    'PASSWORD_TOO_WEAK': 'Weak Password',

    // Network Errors
    'NETWORK_ERROR': 'No Internet Connection',
    'TIMEOUT': 'Request Timed Out',
    'CONNECTION_ERROR': 'Connection Failed',

    // Resource Errors
    'NOT_FOUND': 'Not Found',
    'CONFLICT': 'Already Exists',
    'DUPLICATE_RECORD': 'Duplicate Entry',

    // Server Errors
    'INTERNAL_SERVER_ERROR': 'Server Error',
    'SERVICE_UNAVAILABLE': 'Service Temporarily Unavailable',

    // Rate Limiting
    'RATE_LIMIT_EXCEEDED': 'Too Many Attempts',

    // File Upload Errors
    'FILE_TOO_LARGE': 'File Too Large',
    'INVALID_FILE_TYPE': 'Invalid File Type',

    // Sync Errors
    'SYNC_FAILED': 'Sync Failed',
    'CONFLICT_DETECTED': 'Sync Conflict',
    'SYNC_IN_PROGRESS': 'Sync in Progress',

    // Business Logic Errors
    'INVALID_TOUCHPOINT_TYPE': 'Invalid Touchpoint',
    'INVALID_STATUS_TRANSITION': 'Status Change Failed',
    'CLIENT_ALREADY_ASSIGNED': 'Client Already Assigned',
  };

  // Error code to user-friendly message mapping
  static const Map<String, String> _errorMessages = {
    // Authentication Errors
    'INVALID_CREDENTIALS': 'Invalid email or password. Please try again.',
    'TOKEN_EXPIRED': 'Your session has expired. Please sign in again.',
    'TOKEN_INVALID': 'Please sign in to continue.',
    'UNAUTHORIZED': 'Please sign in to access this feature.',

    // Permission Errors
    'FORBIDDEN': 'You don\'t have permission to perform this action.',
    'INSUFFICIENT_PERMISSIONS': 'Your account doesn\'t have access to this feature.',

    // Validation Errors
    'VALIDATION_ERROR': 'Please check the highlighted fields and try again.',
    'INVALID_INPUT': 'Please check your input and try again.',
    'INVALID_EMAIL': 'Please enter a valid email address.',
    'INVALID_PHONE': 'Please enter a valid phone number.',
    'PASSWORD_TOO_WEAK': 'Your password is too weak.',

    // Network Errors
    'NETWORK_ERROR': 'Please check your internet connection and try again.',
    'TIMEOUT': 'The request took too long. Please try again.',
    'CONNECTION_ERROR': 'Unable to connect to the server.',

    // Resource Errors
    'NOT_FOUND': 'The requested information could not be found.',
    'CONFLICT': 'This record already exists.',
    'DUPLICATE_RECORD': 'This entry already exists in the system.',

    // Server Errors
    'INTERNAL_SERVER_ERROR': 'Something went wrong on our end. Please try again.',
    'SERVICE_UNAVAILABLE': 'This service is temporarily unavailable.',

    // Rate Limiting
    'RATE_LIMIT_EXCEEDED': 'You\'ve made too many requests. Please wait a moment.',

    // File Upload Errors
    'FILE_TOO_LARGE': 'The file is too large. Maximum size is 10MB.',
    'INVALID_FILE_TYPE': 'This file type is not supported.',

    // Sync Errors
    'SYNC_FAILED': 'Unable to sync your data. Please try again.',
    'CONFLICT_DETECTED': 'Changes conflict with server data.',
    'SYNC_IN_PROGRESS': 'Please wait for sync to complete.',

    // Business Logic Errors
    'INVALID_TOUCHPOINT_TYPE': 'You can only create visit touchpoints.',
    'INVALID_STATUS_TRANSITION': 'This status change is not allowed.',
    'CLIENT_ALREADY_ASSIGNED': 'This client is already assigned to another agent.',
  };

  // Error code to actionable suggestions mapping
  static const Map<String, List<String>> _errorSuggestions = {
    // Authentication Errors
    'INVALID_CREDENTIALS': [
      'Check your email spelling',
      'Reset your password if needed',
    ],
    'TOKEN_EXPIRED': [
      'Your session lasts 24 hours',
      'Sign in to continue',
    ],
    'TOKEN_INVALID': [
      'You may have been signed out',
      'Sign in to continue',
    ],
    'UNAUTHORIZED': [
      'Create an account if you don\'t have one',
    ],

    // Permission Errors
    'FORBIDDEN': [
      'Contact your administrator',
      'Check your account permissions',
    ],
    'INSUFFICIENT_PERMISSIONS': [
      'Upgrade your account',
      'Contact your administrator',
    ],

    // Validation Errors
    'VALIDATION_ERROR': [
      'All required fields must be filled',
      'Check for any formatting errors',
    ],
    'INVALID_EMAIL': [
      'Example: user@example.com',
      'Check for typos',
    ],
    'INVALID_PHONE': [
      'Include area code',
      'Use format: 09XX XXX XXXX',
    ],
    'PASSWORD_TOO_WEAK': [
      'Use at least 8 characters',
      'Include numbers and symbols',
    ],

    // Network Errors
    'NETWORK_ERROR': [
      'Turn on mobile data or Wi-Fi',
      'Check your signal strength',
    ],
    'TIMEOUT': [
      'Check your connection speed',
      'Try again later',
    ],
    'CONNECTION_ERROR': [
      'Check if you\'re online',
      'The server may be temporarily unavailable',
    ],

    // Resource Errors
    'NOT_FOUND': [
      'It may have been deleted',
      'Check if the link is correct',
    ],
    'CONFLICT': [
      'Use a different name/email',
      'Check for duplicates',
    ],
    'DUPLICATE_RECORD': [
      'Check if you already created this',
      'Use a unique identifier',
    ],

    // Server Errors
    'INTERNAL_SERVER_ERROR': [
      'Wait a moment and retry',
      'If the problem persists, contact support',
    ],
    'SERVICE_UNAVAILABLE': [
      'We\'re performing maintenance',
      'Please try again later',
    ],

    // Rate Limiting
    'RATE_LIMIT_EXCEEDED': [
      'Wait 60 seconds before trying again',
      'Don\'t tap the button repeatedly',
    ],

    // File Upload Errors
    'FILE_TOO_LARGE': [
      'Choose a smaller file',
      'Compress the image before uploading',
    ],
    'INVALID_FILE_TYPE': [
      'Use: JPG, PNG, GIF, PDF',
      'Choose a different file',
    ],

    // Sync Errors
    'SYNC_FAILED': [
      'Check your internet connection',
      'Pull to refresh to retry',
    ],
    'CONFLICT_DETECTED': [
      'Server data will be used',
      'Your changes will be discarded',
    ],
    'SYNC_IN_PROGRESS': [
      'Sync runs automatically',
      'Don\'t close the app',
    ],

    // Business Logic Errors
    'INVALID_TOUCHPOINT_TYPE': [
      'Contact your administrator to update your role',
    ],
    'INVALID_STATUS_TRANSITION': [
      'Check the current status',
      'Follow the approved workflow',
    ],
    'CLIENT_ALREADY_ASSIGNED': [
      'Choose a different client',
      'Contact the assigned agent',
    ],
  };

  // Error code to icon mapping
  static final Map<String, IconData> _errorIcons = {
    // Authentication Errors
    'INVALID_CREDENTIALS': LucideIcons.lock,
    'TOKEN_EXPIRED': LucideIcons.clock,
    'TOKEN_INVALID': LucideIcons.shield,
    'UNAUTHORIZED': LucideIcons.user,

    // Permission Errors
    'FORBIDDEN': LucideIcons.shieldAlert,
    'INSUFFICIENT_PERMISSIONS': LucideIcons.userX,

    // Validation Errors
    'VALIDATION_ERROR': LucideIcons.alertCircle,
    'INVALID_INPUT': LucideIcons.edit,
    'INVALID_EMAIL': LucideIcons.mail,
    'INVALID_PHONE': LucideIcons.phone,
    'PASSWORD_TOO_WEAK': LucideIcons.lock,

    // Network Errors
    'NETWORK_ERROR': LucideIcons.wifiOff,
    'TIMEOUT': LucideIcons.timer,
    'CONNECTION_ERROR': LucideIcons.refreshCw,

    // Resource Errors
    'NOT_FOUND': LucideIcons.search,
    'CONFLICT': LucideIcons.copy,
    'DUPLICATE_RECORD': LucideIcons.copy,

    // Server Errors
    'INTERNAL_SERVER_ERROR': LucideIcons.server,
    'SERVICE_UNAVAILABLE': LucideIcons.activity,

    // Rate Limiting
    'RATE_LIMIT_EXCEEDED': LucideIcons.gauge,

    // File Upload Errors
    'FILE_TOO_LARGE': LucideIcons.file,
    'INVALID_FILE_TYPE': LucideIcons.fileX,

    // Sync Errors
    'SYNC_FAILED': LucideIcons.refreshCw,
    'CONFLICT_DETECTED': LucideIcons.gitMerge,
    'SYNC_IN_PROGRESS': LucideIcons.loader,

    // Business Logic Errors
    'INVALID_TOUCHPOINT_TYPE': LucideIcons.mapPin,
    'INVALID_STATUS_TRANSITION': LucideIcons.workflow,
    'CLIENT_ALREADY_ASSIGNED': LucideIcons.users,
  };

  // Error code to color mapping
  static final Map<String, Color> _errorColors = {
    // Authentication Errors - Red/Orange
    'INVALID_CREDENTIALS': Color(0xFFEF4444), // Red
    'TOKEN_EXPIRED': Color(0xFFF59E0B), // Orange
    'TOKEN_INVALID': Color(0xFFEF4444), // Red
    'UNAUTHORIZED': Color(0xFFF59E0B), // Orange

    // Permission Errors - Purple
    'FORBIDDEN': Color(0xFF8B5CF6), // Purple
    'INSUFFICIENT_PERMISSIONS': Color(0xFFA78BFA), // Light Purple

    // Validation Errors - Amber
    'VALIDATION_ERROR': Color(0xFFF59E0B), // Amber
    'INVALID_INPUT': Color(0xFFF59E0B),
    'INVALID_EMAIL': Color(0xFFF59E0B),
    'INVALID_PHONE': Color(0xFFF59E0B),
    'PASSWORD_TOO_WEAK': Color(0xFFF59E0B),

    // Network Errors - Blue
    'NETWORK_ERROR': Color(0xFF3B82F6), // Blue
    'TIMEOUT': Color(0xFF3B82F6),
    'CONNECTION_ERROR': Color(0xFF3B82F6),

    // Resource Errors - Slate
    'NOT_FOUND': Color(0xFF64748B), // Slate
    'CONFLICT': Color(0xFF64748B),
    'DUPLICATE_RECORD': Color(0xFF64748B),

    // Server Errors - Red
    'INTERNAL_SERVER_ERROR': Color(0xFFDC2626), // Dark Red
    'SERVICE_UNAVAILABLE': Color(0xFFF87171), // Light Red

    // Rate Limiting - Yellow
    'RATE_LIMIT_EXCEEDED': Color(0xFFEAB308), // Yellow

    // File Upload Errors - Pink
    'FILE_TOO_LARGE': Color(0xFFEC4899), // Pink
    'INVALID_FILE_TYPE': Color(0xFFEC4899),

    // Sync Errors - Teal
    'SYNC_FAILED': Color(0xFF14B8A6), // Teal
    'CONFLICT_DETECTED': Color(0xFF14B8A6),
    'SYNC_IN_PROGRESS': Color(0xFF2DD4BF), // Light Teal

    // Business Logic Errors - Indigo
    'INVALID_TOUCHPOINT_TYPE': Color(0xFF6366F1), // Indigo
    'INVALID_STATUS_TRANSITION': Color(0xFF6366F1),
    'CLIENT_ALREADY_ASSIGNED': Color(0xFF6366F1),
  };
}
