import 'package:flutter/material.dart';
import '../../../clients/data/models/client_model.dart';

/// Client Information Expansion Panel
/// Displays all client demographic and classification information
/// organized into 8 subsections with 46+ fields
class ClientInformationExpansionPanel extends StatelessWidget {
  final Client client;

  const ClientInformationExpansionPanel({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'CLIENT INFORMATION',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        '44 fields',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsection('Personal Information', _buildPersonalInfo()),
              _buildSubsection('Employment Details', _buildEmploymentDetails()),
              _buildSubsection('Classification', _buildClassification()),
              _buildSubsection('Location', _buildLocation()),
              _buildSubsection('UDI (Unique Document Identifier)', _buildUDI()),
              _buildSubsection('Loan Information', _buildLoanInformation()),
              _buildSubsection('Legacy PCNICMS Information', _buildLegacyPCNICMS()),
              _buildSubsection('System Information', _buildSystemInformation()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubsection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPersonalInfo() {
    return [
      _buildField('Full Name', client.fullName),
      _buildField('First Name', client.firstName),
      _buildField('Middle Name', client.middleName ?? '—'),
      _buildField('Last Name', client.lastName),
      // Legacy fields
      _buildField('Extension Name', client.extName ?? '—'),
      _buildField('Birth Date', _formatDate(client.birthDate)),
      _buildField('Age', '${_calculateAge(client.birthDate)} years old'),
      _buildField('DOB (Text)', client.dob ?? '—'),
    ];
  }

  List<Widget> _buildEmploymentDetails() {
    return [
      _buildField('Agency Name', client.agencyName ?? '—'),
      _buildField('Department', client.department ?? '—'),
      _buildField('Position', client.position ?? '—'),
      _buildField('Employment Status', client.employmentStatus ?? '—'),
      _buildField('Payroll Date', client.payrollDate ?? '—'),
      _buildField('Tenure', client.tenure != null ? '${client.tenure} years' : '—'),
      _buildField('G Company', client.gCompany ?? '—'),
      _buildField('G Status', client.gStatus ?? '—'),
    ];
  }

  List<Widget> _buildClassification() {
    return [
      _buildField('Client Type', client.clientType.name),
      _buildField('Product Type', client.productTypeDisplay),
      _buildField('Market Type', client.marketTypeDisplay ?? '—'),
      _buildField('Pension Type', client.pensionTypeDisplay),
      _buildField('PAN', client.pan ?? '—'),
      _buildField('Rank', client.rank ?? '—'),
    ];
  }

  List<Widget> _buildLocation() {
    return [
      _buildField('Region', client.region ?? '—'),
      _buildField('Province', client.province ?? '—'),
      _buildField('Municipality', client.municipality ?? '—'),
      _buildField('Barangay', client.barangay ?? '—'),
      // fullAddress is now a getter, not a field - don't display in expansion panel
      _buildField('PSGC ID', client.psgcId?.toString() ?? '—'),
    ];
  }

  List<Widget> _buildUDI() {
    return [
      _buildField('UDI', client.udi ?? '—'),
      _buildField('Account Code', client.accountCode ?? '—'),
      _buildField('Account Number', client.accountNumber ?? '—'),
      _buildField('Unit Code', client.unitCode ?? '—'),
      _buildField('PCNI Acct Code', client.pcniAcctCode ?? '—'),
    ];
  }

  List<Widget> _buildLoanInformation() {
    return [
      _buildField('Loan Released', client.loanReleased ? 'Yes' : 'No'),
      _buildField('Loan Released At', _formatDateTime(client.loanReleasedAt)),
      _buildField('ATM Number', client.atmNumber ?? '—'),
      _buildField('Monthly Pension', client.monthlyPensionAmount?.toString() ?? '—'),
      _buildField('Monthly Gross', client.monthlyPensionGross?.toString() ?? '—'),
    ];
  }

  List<Widget> _buildLegacyPCNICMS() {
    return [
      _buildField('Applicable RA', client.applicableRepublicAct ?? '—'),
      _buildField('Status', client.status ?? 'Active'),
    ];
  }

  List<Widget> _buildSystemInformation() {
    return [
      _buildField('Client ID', client.id ?? '—'),
      _buildField('Is Starred', client.isStarred ? 'Yes' : 'No'),
      _buildField('Remarks', client.remarks ?? '—'),
      _buildField('Created At', _formatDateTime(client.createdAt)),
      _buildField('Updated At', _formatDateTime(client.updatedAt)),
      _buildField('Deleted At', _formatDateTime(client.deletedAt)),
    ];
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
