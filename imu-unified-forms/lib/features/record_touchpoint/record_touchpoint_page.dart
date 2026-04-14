import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/models/call_model.dart';
import 'package:imu_flutter/models/touchpoint_model_v2.dart';
import 'package:imu_flutter/widgets/visit_form_widget.dart';
import 'package:imu_flutter/widgets/call_form_widget.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/call_api_service.dart';
import 'package:imu_flutter/services/api/touchpoint_v2_api_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';
import 'package:uuid/uuid.dart';

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
      // Step 1: Create visit via API
      final visitService = ref.read(visitApiServiceProvider);
      final createdVisit = await visitService.createVisit(visit);

      // Step 2: Fetch existing touchpoints for this client to determine next number
      final touchpointService = ref.read(touchpointV2ApiServiceProvider);
      final existingTouchpoints = await touchpointService.fetchTouchpoints(
        clientId: widget.clientId,
      );

      // Step 3: Calculate next touchpoint number
      final nextTouchpointNumber = existingTouchpoints.length + 1;

      if (nextTouchpointNumber > 7) {
        if (mounted) {
          HapticUtils.error();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum touchpoints (7) already reached for this client'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Step 4: Create touchpoint linking to the visit
      final touchpoint = TouchpointV2(
        id: const Uuid().v4(),
        clientId: widget.clientId,
        userId: createdVisit.userId,
        visitId: createdVisit.id,
        callId: null,
        touchpointNumber: nextTouchpointNumber,
        type: 'Visit',
        rejectionReason: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await touchpointService.createTouchpoint(touchpoint);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit recorded successfully (Touchpoint $nextTouchpointNumber/7)'),
            duration: const Duration(seconds: 2),
          ),
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
      // Step 1: Create call via API
      final callService = ref.read(callApiServiceProvider);
      final createdCall = await callService.createCall(call);

      // Step 2: Fetch existing touchpoints for this client to determine next number
      final touchpointService = ref.read(touchpointV2ApiServiceProvider);
      final existingTouchpoints = await touchpointService.fetchTouchpoints(
        clientId: widget.clientId,
      );

      // Step 3: Calculate next touchpoint number
      final nextTouchpointNumber = existingTouchpoints.length + 1;

      if (nextTouchpointNumber > 7) {
        if (mounted) {
          HapticUtils.error();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum touchpoints (7) already reached for this client'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Step 4: Create touchpoint linking to the call
      final touchpoint = TouchpointV2(
        id: const Uuid().v4(),
        clientId: widget.clientId,
        userId: createdCall.userId,
        visitId: null,
        callId: createdCall.id,
        touchpointNumber: nextTouchpointNumber,
        type: 'Call',
        rejectionReason: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await touchpointService.createTouchpoint(touchpoint);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call recorded successfully (Touchpoint $nextTouchpointNumber/7)'),
            duration: const Duration(seconds: 2),
          ),
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
