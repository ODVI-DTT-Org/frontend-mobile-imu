import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/models/call_model.dart';
import 'package:imu_flutter/widgets/visit_form_widget.dart';
import 'package:imu_flutter/widgets/call_form_widget.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/call_api_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Record Touchpoint Page - Allows users to create visit or call touchpoints
class RecordTouchpointPage extends ConsumerStatefulWidget {
  final String clientId;

  const RecordTouchpointPage({
    super.key,
    required this.clientId,
  });

  @override
  ConsumerState<RecordTouchpointPage> createState() => _RecordTouchpointPageState();
}

class _RecordTouchpointPageState extends ConsumerState<RecordTouchpointPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleVisitSubmit(Visit visit) async {
    setState(() => _isLoading = true);

    try {
      // Create visit via API
      final service = ref.read(visitApiServiceProvider);
      final createdVisit = await service.createVisit(visit);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit recorded successfully')),
        );
        Navigator.of(context).pop(createdVisit);
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record visit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCallSubmit(Call call) async {
    setState(() => _isLoading = true);

    try {
      // Create call via API
      final service = ref.read(callApiServiceProvider);
      final createdCall = await service.createCall(call);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call recorded successfully')),
        );
        Navigator.of(context).pop(createdCall);
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record call: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Touchpoint'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.mapPin),
              text: 'Visit',
            ),
            Tab(
              icon: Icon(LucideIcons.phone),
              text: 'Call',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVisitTab(),
          _buildCallTab(),
        ],
      ),
    );
  }

  Widget _buildVisitTab() {
    return VisitFormWidget(
      initialVisit: Visit(
        id: '', // Will be generated on submit
        clientId: widget.clientId,
        userId: '', // Will be filled by API
        type: 'regular_visit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      onSubmit: _handleVisitSubmit,
      isLoading: _isLoading,
    );
  }

  Widget _buildCallTab() {
    return CallFormWidget(
      initialCall: Call(
        id: '', // Will be generated on submit
        clientId: widget.clientId,
        userId: '', // Will be filled by API
        phoneNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      onSubmit: _handleCallSubmit,
      isLoading: _isLoading,
    );
  }
}
