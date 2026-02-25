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

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Loan Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Form
              _buildInputCard(),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(LucideIcons.calculator),
                      label: const Text('Calculate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ],
              ),

              // Results
              if (_result != null) ...[
                const SizedBox(height: 32),
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildScheduleCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Principal
          TextFormField(
            controller: _principalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Principal Amount',
              prefixText: '₱ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter principal amount';
              if (double.tryParse(value.replaceAll(',', '')) == null) return 'Invalid amount';
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            _formatCurrency(_result!.monthlyPayment),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
          const Text(
            'Monthly Payment',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultItem('Total Interest', _formatCurrency(_result!.totalInterest)),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _buildResultItem('Total Amount', _formatCurrency(_result!.totalAmount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
                  const Text(
                    'Amortization Schedule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Icon(_showSchedule ? LucideIcons.chevronUp : LucideIcons.chevronDown),
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
                          child: Text('Mo.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Principal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Interest', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Balance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                    ..._result!.schedule.map((entry) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${entry.month}', style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(_formatCurrency(entry.principal), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(_formatCurrency(entry.interest), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(_formatCurrency(entry.balance), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
