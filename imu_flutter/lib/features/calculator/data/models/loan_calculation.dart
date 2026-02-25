/// Loan calculation model with amortization schedule
class LoanCalculation {
  final double principal;
  final double annualRate;
  final int termMonths;
  final double monthlyPayment;
  final double totalInterest;
  final double totalAmount;
  final List<AmortizationEntry> schedule;

  LoanCalculation({
    required this.principal,
    required this.annualRate,
    required this.termMonths,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalAmount,
    required this.schedule,
  });
}

class AmortizationEntry {
  final int month;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  AmortizationEntry({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}
