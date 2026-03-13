import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';

class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    ref.invalidate(todayTasksProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _markTaskDone(MyDayTask task) async {
    HapticUtils.success();

    try {
      final myDayApi = ref.read(myDayApiServiceProvider);
      await myDayApi.completeTask(task.id);

      ref.invalidate(todayTasksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.clientName} marked as done'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _startTask(MyDayTask task) async {
    HapticUtils.mediumImpact();

    try {
      final myDayApi = ref.read(myDayApiServiceProvider);
      await myDayApi.startTask(task.id);
      ref.invalidate(todayTasksProvider);
    } catch (e) {
      debugPrint('Failed to start task: $e');
    }

    if (task.taskType == 'visit') {
      // Navigate to client detail to start visit
      context.push('/clients/${task.clientId}');
    } else {
      // Show call modal
      _showCallModal(task);
    }
  }

  void _showCallModal(MyDayTask task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.green[100],
              child: Icon(
                LucideIcons.phone,
                color: Colors.green[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              task.clientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.taskType.toUpperCase(),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticUtils.lightImpact();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling client...')),
                      );
                    },
                    icon: const Icon(LucideIcons.phone),
                    label: const Text('Call Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticUtils.lightImpact();
                      Navigator.pop(context);
                      _markTaskDone(task);
                    },
                    icon: const Icon(LucideIcons.check),
                    label: const Text('Mark Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    HapticUtils.lightImpact();
    _showAddTaskModal();
  }

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskModal(
        onSave: (taskData) {
          HapticUtils.success();
          ref.invalidate(todayTasksProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final summaryAsync = ref.watch(taskSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: _handleRefresh,
          child: tasksAsync.when(
            data: (tasks) => _buildContent(tasks, summaryAsync),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(todayTasksProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<MyDayTask> tasks, AsyncValue<Map<String, int>> summaryAsync) {
    final pendingTasks = tasks.where((t) => t.status == 'pending').toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();
    final inProgressTasks = tasks.where((t) => t.status == 'in_progress').toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(17),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Day',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // Filter button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.filter),
                    color: const Color(0xFF0F172A),
                    onPressed: () {
                      HapticUtils.lightImpact();
                      // Show filter options
                    },
                  ),
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: summaryAsync.when(
              data: (summary) => Row(
                children: [
                  // Progress Circle
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: (summary['total'] ?? 0) == 0
                                  ? 0
                                  : (summary['completed'] ?? 0) / (summary['total'] ?? 1),
                              strokeWidth: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${((summary['completed'] ?? 0) / ((summary['total'] ?? 1).clamp(1, 100)) * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary['completed']}/${summary['total']} Tasks',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatChip(
                              '${pendingTasks.where((t) => t.taskType == 'visit').length}',
                              'Visits',
                              LucideIcons.mapPin,
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              '${pendingTasks.where((t) => t.taskType == 'call').length}',
                              'Calls',
                              LucideIcons.phone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Could not load summary', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // In Progress Tasks
          if (inProgressTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...inProgressTasks.map((task) => _TaskCard(
                  task: task,
                  onMarkDone: () => _markTaskDone(task),
                  onStart: () => _startTask(task),
                )),
            const SizedBox(height: 16),
          ],

          // Pending Tasks
          if (pendingTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...pendingTasks.map((task) => _TaskCard(
                  task: task,
                  onMarkDone: () => _markTaskDone(task),
                  onStart: () => _startTask(task),
                )),
          ],

          // Completed Tasks
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...completedTasks.map((task) => _TaskCard(
                  task: task,
                  isCompleted: true,
                )),
          ],

          // Empty state
          if (tasks.isEmpty)
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tasks for today',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final MyDayTask task;
  final bool isCompleted;
  final VoidCallback? onMarkDone;
  final VoidCallback? onStart;

  const _TaskCard({
    required this.task,
    this.isCompleted = false,
    this.onMarkDone,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isVisit = task.taskType == 'visit';
    final isInProgress = task.status == 'in_progress';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInProgress
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : Colors.grey.shade200,
          width: isInProgress ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isCompleted ? null : onStart,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: isCompleted ? null : onMarkDone,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF22C55E) : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF22C55E) : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey.shade100
                      : (isVisit ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF22C55E).withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                  color: isCompleted
                      ? Colors.grey
                      : (isVisit ? const Color(0xFF3B82F6) : const Color(0xFF22C55E)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.clientName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.shade100
                                : const Color(0xFF0F172A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.taskType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? Colors.grey
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isInProgress) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(task.scheduledTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.grey : const Color(0xFF0F172A),
                    ),
                  ),
                  if (!isCompleted)
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $ampm';
  }
}

/// Add Task Modal for creating new tasks
class _AddTaskModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddTaskModal({required this.onSave});

  @override
  State<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<_AddTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _titleController = TextEditingController();
  String _taskType = 'visit';
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _clientNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Name
                      const Text(
                        'Client Name *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter client name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Task Title
                      const Text(
                        'Task Title *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter task title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Task Type
                      const Text(
                        'Task Type',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticUtils.lightImpact();
                                setState(() => _taskType = 'visit');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _taskType == 'visit'
                                      ? const Color(0xFF3B82F6)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.mapPin,
                                      size: 18,
                                      color: _taskType == 'visit'
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Visit',
                                      style: TextStyle(
                                        color: _taskType == 'visit'
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticUtils.lightImpact();
                                setState(() => _taskType = 'call');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _taskType == 'call'
                                      ? const Color(0xFF22C55E)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.phone,
                                      size: 18,
                                      color: _taskType == 'call'
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Call',
                                      style: TextStyle(
                                        color: _taskType == 'call'
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scheduled Time
                      const Text(
                        'Scheduled Time',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(LucideIcons.clock, size: 18),
                          ),
                          child: Text(_formatTime(_scheduledTime)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleSave,
                          child: const Text('ADD TASK'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    HapticUtils.lightImpact();
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (time != null) {
      setState(() => _scheduledTime = time);
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticUtils.success();

      widget.onSave({
        'clientName': _clientNameController.text,
        'title': _titleController.text,
        'taskType': _taskType,
        'scheduledTime': DateTime.now().copyWith(
          hour: _scheduledTime.hour,
          minute: _scheduledTime.minute,
        ),
      });

      Navigator.pop(context);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
