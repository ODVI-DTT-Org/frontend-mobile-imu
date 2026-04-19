import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/loan_details_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('LoanDetailsCard', () {
    testWidgets('renders all three field labels', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: null,
        loanType: null,
        udiController: TextEditingController(),
        onProductTypeChanged: (_) {},
        onLoanTypeChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Product Type'), findsOneWidget);
      expect(find.text('Loan Type'), findsOneWidget);
      expect(find.text('UDI Number'), findsOneWidget);
    });

    testWidgets('shows error texts when showErrors true and all null/empty', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: null,
        loanType: null,
        udiController: TextEditingController(),
        onProductTypeChanged: (_) {},
        onLoanTypeChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('product type is required'), findsOneWidget);
      expect(find.text('loan type is required'), findsOneWidget);
      expect(find.text('UDI number is required'), findsOneWidget);
    });

    testWidgets('no errors shown when all fields filled', (tester) async {
      await tester.pumpWidget(_wrap(LoanDetailsCard(
        productType: ProductType.pnpPension,
        loanType: LoanType.newLoan,
        udiController: TextEditingController(text: '50000'),
        onProductTypeChanged: (_) {},
        onLoanTypeChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('product type is required'), findsNothing);
      expect(find.text('loan type is required'), findsNothing);
      expect(find.text('UDI number is required'), findsNothing);
    });
  });
}
