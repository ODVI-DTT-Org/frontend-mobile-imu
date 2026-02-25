import '../models/loan_calculation.dart';

/// Service for calculating loan payments and amortization schedules
class LoanCalculatorService {
  /// Calculate monthly payment using amortization formula
  /// M = P × [r(1+r)^n] / [(1+r)^n – 1]
  double calculateMonthlyPayment(double principal, double annualRate, int termMonths) {
    if (principal <= 0 || termMonths <= 0) return 0;
    if (annualRate <= 0) return principal / termMonths;

    final monthlyRate = annualRate / 12 / 100;
    final factor = (1 + monthlyRate);
    final factorPow = _pow(factor, termMonths);

    return principal * (monthlyRate * factorPow) / (factorPow - 1);
  }

  /// Calculate full loan details with amortization schedule
  LoanCalculation calculate(double principal, double annualRate, int termMonths) {
    final monthlyPayment = calculateMonthlyPayment(principal, annualRate, termMonths);
    final totalAmount = monthlyPayment * termMonths;
    final totalInterest = totalAmount - principal;
    final schedule = _generateSchedule(principal, annualRate, termMonths, monthlyPayment);

    return LoanCalculation(
      principal: principal,
      annualRate: annualRate,
      termMonths: termMonths,
      monthlyPayment: monthlyPayment,
      totalInterest: totalInterest,
      totalAmount: totalAmount,
      schedule: schedule,
    );
  }

  /// Generate amortization schedule
  List<AmortizationEntry> _generateSchedule(
    double principal,
    double annualRate,
    int termMonths,
    double monthlyPayment,
  ) {
    final schedule = <AmortizationEntry>[];
    var balance = principal;
    final monthlyRate = annualRate / 12 / 100;

    for (var month = 1; month <= termMonths; month++) {
      final interest = balance * monthlyRate;
      final principalPaid = monthlyPayment - interest;
      balance = (balance - principalPaid).clamp(0, double.infinity);

      schedule.add(AmortizationEntry(
        month: month,
        payment: monthlyPayment,
        principal: principalPaid,
        interest: interest,
        balance: balance,
      ));
    }

    return schedule;
  }

  /// Custom power function to avoid importing dart:math
  double _pow(double base, int exponent) {
    if (exponent == 0) return 1;
    var result = base;
    for (var i = 1; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
