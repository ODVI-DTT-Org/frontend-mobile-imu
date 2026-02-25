import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Light theme colors
  static const Color primary = Color(0xFF334155); // slate-700
  static const Color secondary = Color(0xFF64748B); // slate-500
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Dark theme colors
  static const Color primaryDark = Color(0xFF60A5FA); // blue-400
  static const Color secondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color errorDark = Color(0xFFF87171);
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);
  static const Color borderDark = Color(0xFF374151);

  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Badge/Chip colors
  static const Color chipBackground = Color(0xFFF3F4F6);
  static const Color interestedBackground = Color(0xFFEAB308); // yellow-500
  static const Color notInterestedBackground = Color(0xFFEF4444); // red-500

  // Touchpoint badge colors
  static const Color visitIcon = Color(0xFF16A34A); // green-600
  static const Color callIcon = Color(0xFF16A34A); // green-600
  static const Color inactiveIcon = Color(0xFF9CA3AF); // gray-400

  // Reason badge colors
  static const Color reasonInterested = Color(0xFFDCFCE7); // green-100
  static const Color reasonInterestedText = Color(0xFF166534); // green-800
  static const Color reasonNotInterested = Color(0xFFFEE2E2); // red-100
  static const Color reasonNotInterestedText = Color(0xFF991B1B); // red-800
  static const Color reasonUndecided = Color(0xFFFEF9C3); // yellow-100
  static const Color reasonUndecidedText = Color(0xFF854D0E); // yellow-800
  static const Color reasonLoanInquiry = Color(0xFFDBEAFE); // blue-100
  static const Color reasonLoanInquiryText = Color(0xFF1E40AF); // blue-800
  static const Color reasonForUpdate = Color(0xFFF3E8FF); // purple-100
  static const Color reasonForUpdateText = Color(0xFF6B21A8); // purple-800
  static const Color reasonForVerification = Color(0xFFFFEDD5); // orange-100
  static const Color reasonForVerificationText = Color(0xFF9A3412); // orange-800
  static const Color reasonDefault = Color(0xFFF3F4F6); // gray-100
  static const Color reasonDefaultText = Color(0xFF1F2937); // gray-800
}
