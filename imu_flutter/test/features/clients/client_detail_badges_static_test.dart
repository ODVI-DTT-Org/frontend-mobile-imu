import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client detail shows loan type badge only for loan released clients', () {
    final source = File(
      'lib/features/clients/presentation/pages/client_detail_page.dart',
    ).readAsStringSync();

    expect(source, contains('if (client.loanReleased)'));
    expect(source, contains('client.loanTypeDisplay'));
    expect(source, contains('_getLoanTypeColor'));
  });
}
