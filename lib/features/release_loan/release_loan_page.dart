import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/release_model.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/widgets/release_form_widget.dart';
import 'package:imu_flutter/widgets/visit_form_widget.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Release Loan Page - Two-step process: Record Visit → Create Release
class ReleaseLoanPage extends ConsumerStatefulWidget {
  final String clientId;

  const ReleaseLoanPage({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<ReleaseLoanPage> createState() => _ReleaseLoanPageState();
}

class _ReleaseLoanPageState extends ConsumerState<ReleaseLoanPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  Visit? _createdVisit;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleVisitSubmit(Visit visit) async {
    setState(() => _isLoading = true);

    try {
      // Create visit via API with type 'release_loan'
      final releaseVisit = visit.copyWith(type: 'release_loan');
      final service = ref.read(visitApiServiceProvider);
      final createdVisit = await service.createVisit(releaseVisit);

      if (mounted) {
        setState(() {
          _createdVisit = createdVisit;
          _isLoading = false;
        });

        HapticUtils.success();
        // Move to release form step
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticUtils.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record visit: $e')),
        );
      }
    }
  }

  Future<void> _handleReleaseSubmit(Release release) async {
    setState(() => _isLoading = true);

    try {
      // Create release via API
      final service = ref.read(releaseApiServiceProvider);

      // Link to the created visit
      final releaseWithVisit = release.copyWith(
        visitId: _createdVisit?.id ?? '',
      );

      final createdRelease = await service.createRelease(releaseWithVisit);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Release submitted for approval')),
        );
        Navigator.of(context).pop(createdRelease);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticUtils.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit release: $e')),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Loan'),
        leading: IconButton(
          icon: Icon(_currentStep > 0 ? LucideIcons.arrowLeft : LucideIcons.x),
          onPressed: _handleBack,
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildVisitStep(),
                _buildReleaseStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepIndicator(1, 'Visit', _currentStep >= 0),
          const Expanded(child: Divider()),
          _buildStepIndicator(2, 'Release', _currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Record Visit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record the client visit details first. This will be linked to your loan release application.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 24),
          VisitFormWidget(
            initialVisit: Visit(
              id: '',
              clientId: widget.clientId,
              userId: '',
              type: 'release_loan',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            onSubmit: _handleVisitSubmit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Loan Release Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the loan release details. Your application will be submitted for manager approval.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visit recorded successfully',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ReleaseFormWidget(
            initialRelease: Release(
              id: '',
              clientId: widget.clientId,
              userId: '',
              visitId: _createdVisit?.id ?? '',
              productType: 'PUSU',
              loanType: 'NEW',
              amount: 0,
              status: 'pending',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            onSubmit: _handleReleaseSubmit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
