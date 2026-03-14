import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../data/models/loan_calculation.dart';
import '../../data/services/loan_calculator_service.dart';

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();
  final _calculatorService = LoanCalculatorService();

  LoanCalculation? _result;
  bool _showSchedule = false;
  String _selectedLoanType = 'pension';

  // Preset loan options
  final List<LoanPreset> _presets = [
    LoanPreset(
      name: 'SSS Pension Loan',
      principal: 50000,
      rate: 10.0,
      term: 24,
      type: 'pension',
      description: 'For SSS pensioners - 10% annual rate',
    ),
    LoanPreset(
      name: 'GSIS Pension Loan',
      principal: 75000,
      rate: 8.5,
      term: 36,
      type: 'pension',
      description: 'For GSIS pensioners - 8.5% annual rate',
    ),
    LoanPreset(
      name: 'Emergency Loan',
      principal: 20000,
      rate: 12.0,
      term: 12,
      type: 'emergency',
      description: 'Quick cash for emergencies',
    ),
    LoanPreset(
      name: 'Business Loan',
      principal: 100000,
      rate: 14.0,
      term: 48,
      type: 'business',
      description: 'For business expansion',
    ),
    LoanPreset(
      name: 'Salary Loan',
      principal: 30000,
      rate: 10.0,
      term: 12,
      type: 'salary',
      description: 'Based on monthly salary',
    ),
  ];

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _applyPreset(LoanPreset preset) {
    HapticUtils.mediumImpact();
    setState(() {
      _principalController.text = preset.principal.toString();
      _rateController.text = preset.rate.toString();
      _termController.text = preset.term.toString();
      _selectedLoanType = preset.type;
      _result = null;
      _showSchedule = false;
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    HapticUtils.mediumImpact();

    final principal = double.parse(_principalController.text.replaceAll(',', ''));
    final rate = double.parse(_rateController.text);
    final term = int.parse(_termController.text);

    setState(() {
      _result = _calculatorService.calculate(principal, rate, term);
      _showSchedule = false;
    });
  }

  void _reset() {
    HapticUtils.lightImpact();
    _principalController.clear();
    _rateController.clear();
    _termController.clear();
    setState(() {
      _result = null;
      _showSchedule = false;
      _selectedLoanType = 'pension';
    });
  }

  String _formatCurrency(double value) {
    return '₱${value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Loan Calculator'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preset Loan Options
              _buildPresetsSection(),
              const SizedBox(height: 20),

              // Input Form
              _buildInputCard(),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(LucideIcons.calculator, size: 18),
                      label: const Text('Calculate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Results
              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildScheduleCard(),
              ],

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Loan Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final preset = _presets[index];
              final isSelected = _selectedLoanType == preset.type &&
                  _principalController.text == preset.principal.toString();

              return GestureDetector(
                onTap: () => _applyPreset(preset),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0F172A) : Colors.grey[300]!,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getLoanIcon(preset.type),
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(preset.principal.toDouble()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${preset.term} months @ ${preset.rate}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getLoanIcon(String type) {
    switch (type) {
      case 'pension':
        return LucideIcons.wallet;
      case 'emergency':
        return LucideIcons.alertCircle;
      case 'business':
        return LucideIcons.briefcase;
      case 'salary':
        return LucideIcons.banknote;
      default:
        return LucideIcons.calculator;
    }
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),

          // Principal
          TextFormField(
            controller: _principalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Principal Amount',
              prefixText: '₱ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0F172A)),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter principal amount';
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Invalid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Interest Rate
          TextFormField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Annual Interest Rate',
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0F172A)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter interest rate';
              if (double.tryParse(value) == null) return 'Invalid rate';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Term
          TextFormField(
            controller: _termController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Loan Term',
              suffixText: 'months',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0F172A)),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter loan term';
              if (int.tryParse(value) == null) return 'Invalid term';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _formatCurrency(_result!.monthlyPayment),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Monthly Payment',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultItem(
                'Total Interest',
                _formatCurrency(_result!.totalInterest),
                LucideIcons.trendingUp,
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              _buildResultItem(
                'Total Amount',
                _formatCurrency(_result!.totalAmount),
                LucideIcons.wallet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final effectiveRate = (_result!.annualRate / 12).toStringAsFixed(3);
    final totalPayments = _result!.termMonths;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Principal', _formatCurrency(_result!.principal)),
          _buildSummaryRow('Annual Rate', '${_result!.annualRate}%'),
          _buildSummaryRow('Monthly Rate', '$effectiveRate%'),
          _buildSummaryRow('Term', '$totalPayments months'),
          _buildSummaryRow('Total Payments', '$totalPayments payments'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total Repayment',
            _formatCurrency(_result!.totalAmount),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? const Color(0xFF0F172A) : Colors.grey[600],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF0F172A),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticUtils.lightImpact();
              setState(() => _showSchedule = !_showSchedule);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Amortization Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showSchedule ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_showSchedule)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey[200]!),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Mo.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Principal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Interest',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ..._result!.schedule.map(
                      (entry) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${entry.month}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _formatCurrency(entry.principal),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _formatCurrency(entry.interest),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _formatCurrency(entry.balance),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loan preset model
class LoanPreset {
  final String name;
  final int principal;
  final double rate;
  final int term;
  final String type;
  final String description;

  const LoanPreset({
    required this.name,
    required this.principal,
    required this.rate,
    required this.term,
    required this.type,
    required this.description,
  });
}
