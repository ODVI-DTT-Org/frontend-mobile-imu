import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../core/utils/haptic_utils.dart';

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  // Mock data for tasks
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': '1',
      'type': 'visit',
      'clientName': 'Maria Santos',
      'address': '123 Main St, Makati',
      'time': '09:00 AM',
      'touchpoint': 2,
      'status': 'pending',
      'productType': 'SSS Pensioner',
    },
    {
      'id': '2',
      'type': 'call',
      'clientName': 'Juan Dela Cruz',
      'phone': '+63 917 123 4567',
      'time': '11:00 AM',
      'touchpoint': 3,
      'status': 'pending',
      'productType': 'GSIS Pensioner',
    },
    {
      'id': '3',
      'type': 'visit',
      'clientName': 'Ana Reyes',
      'address': '789 Pine Rd, Pasig',
      'time': '02:00 PM',
      'touchpoint': 1,
      'status': 'completed',
      'productType': 'SSS Pensioner',
    },
    {
      'id': '4',
      'type': 'call',
      'clientName': 'Carlos Mendoza',
      'phone': '+63 919 555 1234',
      'time': '04:00 PM',
      'touchpoint': 5,
      'status': 'pending',
      'productType': 'GSIS Pensioner',
    },
  ];

  List<Map<String, dynamic>> get _pendingTasks =>
      _tasks.where((t) => t['status'] == 'pending').toList();

  List<Map<String, dynamic>> get _completedTasks =>
      _tasks.where((t) => t['status'] == 'completed').toList();

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _markTaskDone(String taskId) {
    final index = _tasks.indexWhere((t) => t['id'] == taskId);
    if (index != -1) {
      HapticUtils.success();
      setState(() {
        _tasks[index]['status'] = 'completed';
        _tasks[index]['completedAt'] = DateTime.now().toIso8601String();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_tasks[index]['clientName']} marked as done'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              HapticUtils.lightImpact();
              setState(() {
                _tasks[index]['status'] = 'pending';
                _tasks[index].remove('completedAt');
              });
            },
          ),
        ),
      );
    }
  }

  void _undoTask(String taskId) {
    final index = _tasks.indexWhere((t) => t['id'] == taskId);
    if (index != -1) {
      HapticUtils.lightImpact();
      setState(() {
        _tasks[index]['status'] = 'pending';
        _tasks[index].remove('completedAt');
      });
    }
  }

  void _startTask(Map<String, dynamic> task) {
    HapticUtils.mediumImpact();

    if (task['type'] == 'visit') {
      // Navigate to client detail to start visit
      context.push('/clients/${task['id']}');
    } else {
      // Show call modal
      _showCallModal(task);
    }
  }

  void _showCallModal(Map<String, dynamic> task) {
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
              task['clientName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task['phone'],
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
                      // In production, launch phone dialer
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${task['phone']}...')),
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
                      _markTaskDone(task['id']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Day'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {
              HapticUtils.lightImpact();
              // Show filter options
            },
          ),
        ],
      ),
      body: PullToRefresh(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Progress',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_completedTasks.length}/${_tasks.length} Tasks',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        CircularProgressIndicator(
                          value: _tasks.isEmpty
                              ? 0
                              : _completedTasks.length / _tasks.length,
                          strokeWidth: 6,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatChip(
                          '${_pendingTasks.where((t) => t['type'] == 'visit').length} Visits',
                          LucideIcons.mapPin,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          '${_pendingTasks.where((t) => t['type'] == 'call').length} Calls',
                          LucideIcons.phone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending Tasks
              if (_pendingTasks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._pendingTasks.map((task) => _TaskCard(
                      task: task,
                      onMarkDone: () => _markTaskDone(task['id']),
                      onStart: () => _startTask(task),
                    )),
              ],

              // Completed Tasks
              if (_completedTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._completedTasks.map((task) => _TaskCard(
                      task: task,
                      isCompleted: true,
                      onUndo: () => _undoTask(task['id']),
                    )),
              ],

              // Empty state
              if (_tasks.isEmpty)
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
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isCompleted;
  final VoidCallback? onMarkDone;
  final VoidCallback? onUndo;
  final VoidCallback? onStart;

  const _TaskCard({
    required this.task,
    this.isCompleted = false,
    this.onMarkDone,
    this.onUndo,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isVisit = task['type'] == 'visit';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.grey[200]! : Colors.grey[200]!,
        ),
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
                onTap: isCompleted ? onUndo : onMarkDone,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey[400]!,
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
                      ? Colors.grey[200]
                      : (isVisit ? Colors.blue[50] : Colors.green[50]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                  color: isCompleted
                      ? Colors.grey
                      : (isVisit ? Colors.blue : Colors.green),
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
                      task['clientName'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVisit ? task['address'] : task['phone'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey[200]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task['productType'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${task['touchpoint']} touchpoint',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
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
                    task['time'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  if (!isCompleted)
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
