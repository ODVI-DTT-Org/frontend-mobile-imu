/// Test script to create an expired JWT token for testing
/// Run with: dart test_expired_token.dart

import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  final storage = const FlutterSecureStorage();

  // Create a token that expired 1 hour ago
  final now = DateTime.now();
  final expiredTime = now.subtract(const Duration(hours: 1));
  final expiredTimestamp = expiredTime.millisecondsSinceEpoch ~/ 1000; // Convert to seconds

  // Create a mock JWT payload (this is NOT a real signed JWT, just for testing)
  final payload = {
    'sub': 'test-user-id',
    'email': 'test@example.com',
    'first_name': 'Test',
    'last_name': 'User',
    'role': 'field_agent',
    'exp': expiredTimestamp, // EXPIRED 1 hour ago
    'iat': now.millisecondsSinceEpoch ~/ 1000,
  };

  print('Creating EXPIRED test token...');
  print('Expired at: $expiredTime');
  print('Current time: $now');
  print('Expired timestamp: $expiredTimestamp');
  print('');

  // Note: This is NOT a valid JWT (not signed)
  // For testing, we'll just encode the payload as base64
  final payloadBase64 = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final fakeToken = 'fake.header.$payloadBase64';

  print('Fake token payload:');
  print(jsonEncode(payload));
  print('');

  // Store it
  await storage.write(key: 'auth_token', value: fakeToken);

  print('✅ Expired test token stored in secure storage!');
  print('');
  print('Now try to login with PIN - it should be REJECTED with "Session expired"');
  print('');
  print('To restore normal operation, login with your email/password');
}
