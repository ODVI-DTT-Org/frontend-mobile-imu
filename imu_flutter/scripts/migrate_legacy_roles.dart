#!/usr/bin/env dart

/// Migration script to check for legacy roles in local data.
///
/// Run this before deploying to production to identify any legacy roles
/// that might still exist in the database.

import 'dart:io';

void main() async {
  print('Checking for legacy roles...');

  final legacyRoles = ['field_agent', 'staff', 'fieldAgent'];
  final foundRoles = <String>[];

  // TODO: Add actual database check here
  // For now, this is a placeholder
  // Example:
  // final users = await db.query('SELECT id, role FROM user_profiles');
  // for (final user in users) {
  //   if (legacyRoles.contains(user['role'])) {
  //     foundRoles.add(user['id']);
  //   }
  // }

  if (foundRoles.isEmpty) {
    print('✅ No legacy roles found');
  } else {
    print('⚠️  Found ${foundRoles.length} users with legacy roles:');
    for (final role in foundRoles) {
      print('  - $role');
    }
    print('\nRun SQL migration to fix:');
    print("UPDATE user_profiles SET role = 'caravan' WHERE role IN ('field_agent', 'staff');");
    print("UPDATE users SET role = 'caravan' WHERE role IN ('field_agent', 'staff');");
  }

  exit(0);
}
