import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/attendance_record.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {

  @override
  Widget build(BuildContext context) {
    final todayRecord = ref.watch(todayAttendanceProvider);
    final isCheckedIn = ref.watch(isCheckedInProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final stats = ref.watch(attendanceStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check In/Out Button
            _buildActionButton(isCheckedIn, todayRecord),
            const SizedBox(height: 24),

            // Today's Summary
            _buildTodayCard(todayRecord),
            const SizedBox(height: 24),

            // Monthly Stats
            _buildStatsCard(stats),
            const SizedBox(height: 24),

            // History
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (records) => records.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: records.take(7).map((r) => _buildHistoryItem(r)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load history'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isCheckedIn, AttendanceRecord? today) {
    final color = isCheckedIn ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    final icon = isCheckedIn ? LucideIcons.logOut : LucideIcons.logIn;
    final label = isCheckedIn ? 'Check Out' : 'Check In';
    final time = isCheckedIn ? today?.checkInTime : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (time != null) ...[
            Text(
              'Checked in at ${_formatTime(time)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCheck(isCheckedIn),
              icon: Icon(icon),
              label: Text(label, style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(AttendanceRecord? today) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today', style: TextStyle(fontWeight: FontWeight.w600)),
              _buildStatusBadge(today?.status ?? AttendanceStatus.absent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  'Check In',
                  today?.checkInTime != null ? _formatTime(today!.checkInTime!) : '--:--',
                  LucideIcons.logIn,
                ),
              ),
              Expanded(
                child: _buildTimeItem(
                  'Check Out',
                  today?.checkOutTime != null ? _formatTime(today!.checkOutTime!) : '--:--',
                  LucideIcons.logOut,
                ),
              ),
              Expanded(
                child: _buildTimeItem(
                  'Hours',
                  today?.formattedHours ?? '--',
                  LucideIcons.clock,
                ),
              ),
            ],
          ),
          if (today?.checkInLocation != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    today?.checkInLocation?.address ?? 'Location captured',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color color;
    String text;

    switch (status) {
      case AttendanceStatus.checkedIn:
        color = const Color(0xFF3B82F6);
        text = 'Active';
        break;
      case AttendanceStatus.checkedOut:
        color = const Color(0xFF22C55E);
        text = 'Complete';
        break;
      case AttendanceStatus.incomplete:
        color = const Color(0xFFF59E0B);
        text = 'Incomplete';
        break;
      case AttendanceStatus.absent:
        color = Colors.grey;
        text = 'Not Started';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${stats['daysWorked']}', 'Days Worked'),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem('${stats['totalHours']}h', 'Total Hours'),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem('${stats['averageHours']}h', 'Avg/Day'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(record.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${record.checkInTime != null ? _formatTime(record.checkInTime!) : '--:--'} - ${record.checkOutTime != null ? _formatTime(record.checkOutTime!) : '--:--'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            record.formattedHours,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(LucideIcons.calendar, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No attendance records yet', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedOut:
        return const Color(0xFF22C55E);
      case AttendanceStatus.checkedIn:
        return const Color(0xFF3B82F6);
      case AttendanceStatus.incomplete:
        return const Color(0xFFF59E0B);
      case AttendanceStatus.absent:
        return Colors.grey;
    }
  }

  Future<void> _handleCheck(bool isCheckingOut) async {
    HapticUtils.mediumImpact();

    await LoadingHelper.withLoading(
      ref: ref,
      message: isCheckingOut ? 'Checking out...' : 'Checking in...',
      operation: () async {
        final locationAsync = ref.read(currentLocationProvider);

        await locationAsync.when(
          data: (location) async {
            final attendanceLocation = AttendanceLocation(
              latitude: location?.latitude ?? 0,
              longitude: location?.longitude ?? 0,
              address: location?.address,
              timestamp: DateTime.now(),
            );

            final notifier = ref.read(todayAttendanceProvider.notifier);
            if (isCheckingOut) {
              await notifier.checkOut(attendanceLocation);
            } else {
              await notifier.checkIn(attendanceLocation);
            }
          },
          loading: () async {
            // Use default location if GPS unavailable
            final attendanceLocation = AttendanceLocation(
              latitude: 0,
              longitude: 0,
              timestamp: DateTime.now(),
            );

            final notifier = ref.read(todayAttendanceProvider.notifier);
            if (isCheckingOut) {
              await notifier.checkOut(attendanceLocation);
            } else {
              await notifier.checkIn(attendanceLocation);
            }
          },
          error: (_, __) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not get location. Please enable GPS.')),
              );
            }
          },
        );
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to ${isCheckingOut ? "check out" : "check in"}: $e')),
          );
        }
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
