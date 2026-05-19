import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit client loan type is optional', () {
    final source = File(
      'lib/features/clients/presentation/pages/edit_client_page.dart',
    ).readAsStringSync();

    final loanTypeField = RegExp(
      r"DropdownButtonFormField<String>\([\s\S]*?labelText: 'Loan Type'[\s\S]*?\),\n\s*const SizedBox\(height: 16\)",
    ).firstMatch(source)?.group(0);

    expect(loanTypeField, isNotNull);
    expect(loanTypeField, isNot(contains("labelText: 'Loan Type *'")));
    expect(loanTypeField, isNot(contains('Required')));
  });
}
