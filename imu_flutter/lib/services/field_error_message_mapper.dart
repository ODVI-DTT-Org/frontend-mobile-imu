/// Field-level error message mapper
///
/// Converts technical field names and validation errors to user-friendly messages
class FieldErrorMessageMapper {
  // Private constructor to prevent instantiation
  FieldErrorMessageMapper._();

  /// Get user-friendly label for field name
  ///
  /// Converts snake_case field names to human-readable labels.
  /// Examples:
  /// - "first_name" → "First name"
  /// - "email" → "Email address"
  /// - "phone_number" → "Phone number"
  static String getFieldLabel(String fieldName) {
    return _fieldLabels[fieldName] ?? _generateLabel(fieldName);
  }

  /// Get user-friendly validation message for field
  ///
  /// Generates contextual validation messages based on field and error type.
  /// Examples:
  /// - ("email", "required") → "Please enter your email address"
  /// - ("email", "invalid") → "Please enter a valid email address"
  /// - ("phone_number", "required") → "Please enter your phone number"
  static String getValidationMessage(String fieldName, String errorCode) {
    final key = '$fieldName.$errorCode';
    return _validationMessages[key] ?? _getDefaultValidationMessage(fieldName, errorCode);
  }

  /// Generate a default validation message when no specific message exists
  static String _getDefaultValidationMessage(String fieldName, String errorCode) {
    final label = getFieldLabel(fieldName);

    switch (errorCode.toLowerCase()) {
      case 'required':
        return 'Please enter your $label';
      case 'invalid':
        return 'Please enter a valid $label';
      case 'too_short':
        return '$label is too short';
      case 'too_long':
        return '$label is too long';
      case 'format':
        return 'Please enter $label in the correct format';
      default:
        return 'Please check your $label';
    }
  }

  /// Generate label from snake_case field name
  static String _generateLabel(String fieldName) {
    // Replace underscores with spaces
    final withSpaces = fieldName.replaceAll('_', ' ');
    // Capitalize first letter of each word
    final words = withSpaces.split(' ');
    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return capitalized;
  }

  // ==================== FIELD LABEL MAPPINGS ====================

  // Personal Information Fields
  static const Map<String, String> _fieldLabels = {
    // Personal fields
    'first_name': 'First name',
    'last_name': 'Last name',
    'middle_name': 'Middle name',
    'email': 'Email address',
    'phone_number': 'Phone number',
    'password': 'Password',

    // Address fields
    'street': 'Street address',
    'barangay': 'Barangay',
    'city_municipality': 'City/Municipality',
    'province': 'Province',
    'zip_code': 'ZIP code',

    // Client fields
    'client_type': 'Client type',
    'product_type': 'Product type',
    'market_type': 'Market type',
    'pension_type': 'Pension type',

    // Touchpoint fields
    'touchpoint_number': 'Touchpoint number',
    'touchpoint_type': 'Touchpoint type',
    'reason': 'Reason',
    'status': 'Status',
    'photo': 'Photo',
    'audio': 'Audio recording',
    'date': 'Date',
    'notes': 'Notes',

    // Agency fields
    'agency_name': 'Agency name',
    'agency_code': 'Agency code',
    'contact_person': 'Contact person',
    'contact_number': 'Contact number',

    // User fields
    'role': 'Role',
    'area': 'Area',
    'assigned_municipalities': 'Assigned municipalities',

    // Common fields
    'name': 'Name',
    'description': 'Description',
    'address': 'Address',
    'confirm_password': 'Confirm password',
  };

  // ==================== VALIDATION MESSAGE MAPPINGS ====================

  // Field-specific validation messages
  static const Map<String, String> _validationMessages = {
    // Email field validations
    'email.required': 'Please enter your email address',
    'email.invalid': 'Please enter a valid email address (e.g., user@example.com)',
    'email.too_short': 'Email address is too short',
    'email.too_long': 'Email address is too long',

    // Phone number field validations
    'phone_number.required': 'Please enter your phone number',
    'phone_number.invalid': 'Please enter a valid phone number (e.g., 09XX XXX XXXX)',
    'phone_number.too_short': 'Phone number is too short',
    'phone_number.too_long': 'Phone number is too long',

    // Password field validations
    'password.required': 'Please enter a password',
    'password.too_short': 'Password must be at least 8 characters',
    'password.too_weak': 'Password is too weak. Include numbers and symbols',
    'password.invalid': 'Password contains invalid characters',

    // Confirm password field validations
    'confirm_password.required': 'Please confirm your password',
    'confirm_password.invalid': 'Passwords do not match',

    // First name field validations
    'first_name.required': 'Please enter your first name',
    'first_name.invalid': 'Please enter a valid first name',
    'first_name.too_short': 'First name is too short',

    // Last name field validations
    'last_name.required': 'Please enter your last name',
    'last_name.invalid': 'Please enter a valid last name',
    'last_name.too_short': 'Last name is too short',

    // Touchpoint type field validations
    'touchpoint_type.required': 'Please select a touchpoint type',
    'touchpoint_type.invalid': 'Invalid touchpoint type',

    // Touchpoint number field validations
    'touchpoint_number.required': 'Please enter a touchpoint number',
    'touchpoint_number.invalid': 'Invalid touchpoint number (must be 1-7)',

    // Reason field validations
    'reason.required': 'Please select a reason',
    'reason.invalid': 'Invalid reason selected',

    // Photo field validations
    'photo.required': 'Please take a photo',
    'photo.invalid': 'Invalid photo format',
    'photo.too_large': 'Photo file is too large (max 10MB)',

    // Audio field validations
    'audio.required': 'Please record audio',
    'audio.invalid': 'Invalid audio format',
    'audio.too_large': 'Audio file is too large (max 10MB)',

    // Agency name field validations
    'agency_name.required': 'Please enter agency name',
    'agency_name.invalid': 'Please enter a valid agency name',

    // Agency code field validations
    'agency_code.required': 'Please enter agency code',
    'agency_code.invalid': 'Please enter a valid agency code',

    // Role field validations
    'role.required': 'Please select a role',
    'role.invalid': 'Invalid role selected',

    // Area field validations
    'area.required': 'Please select an area',
    'area.invalid': 'Invalid area selected',

    // Address field validations
    'street.required': 'Please enter your street address',
    'barangay.required': 'Please enter your barangay',
    'city_municipality.required': 'Please enter your city or municipality',
    'province.required': 'Please select a province',
    'zip_code.required': 'Please enter your ZIP code',
    'zip_code.invalid': 'Please enter a valid ZIP code',
  };
}
