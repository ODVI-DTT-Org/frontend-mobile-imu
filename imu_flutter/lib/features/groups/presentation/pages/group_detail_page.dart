import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/groups_api_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/group_model.dart';

/// Group detail provider
final groupDetailProvider = FutureProvider.family<ClientGroup?, String>((ref, groupId) async {
  final groupsApi = ref.watch(groupsApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await groupsApi.fetchGroup(groupId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localGroup = await hiveService.getGroup(groupId);
      if (localGroup != null) {
        return ClientGroup.fromJson(localGroup);
      }
      return null;
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localGroup = await hiveService.getGroup(groupId);
    if (localGroup != null) {
      return ClientGroup.fromJson(localGroup);
    }
    return null;
  }
});

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  final _hiveService = HiveService();

  ClientGroup? _group;
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading group...',
      operation: () async {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        final groupData = await _hiveService.getGroup(widget.groupId);
        if (groupData != null && mounted) {
          setState(() {
            _group = ClientGroup.fromJson(groupData);
            _members = _loadMembers();
            _isLoading = false;
          });
        } else {
          // Try API
          final groupsApi = ref.read(groupsApiServiceProvider);
          try {
            final group = await groupsApi.fetchGroup(widget.groupId);
            if (group != null && mounted) {
              setState(() {
                _group = group;
                _members = _loadMembers();
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        }
      },
    );
  }

  List<Map<String, dynamic>> _loadMembers() {
    // Load members from local storage
    // In production, this would be fetched from the API
    return [];
  }

  Future<void> _handleDelete() async {
    if (_group == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete ${_group!.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticUtils.delete();

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting group...',
        operation: () async {
          await _hiveService.deleteGroup(widget.groupId);
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete group: $e')),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted')),
        );
        context.pop();
      }
    }
  }

  void _editGroup() {
    HapticUtils.lightImpact();
    _showEditGroupDialog();
  }

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: _group?.name ?? '');
    final descriptionController = TextEditingController(text: _group?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group name is required')),
                );
                return;
              }

              final updatedGroup = _group!.copyWith(
                name: nameController.text,
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
              );

              await LoadingHelper.withLoading(
                ref: ref,
                message: 'Updating group...',
                operation: () async {
                  await _hiveService.updateGroup(updatedGroup.toJson());
                  ref.invalidate(groupsProvider);
                },
                onError: (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update group: $e')),
                    );
                  }
                },
              );

              if (mounted) {
                Navigator.pop(context);
                _loadGroup();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addMember() {
    HapticUtils.lightImpact();
    // TODO: Show member selection dialog - stub implementation
    LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading members...',
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add member - Coming soon')),
          );
        }
      },
    );
  }

  void _removeMember(String memberId) {
    HapticUtils.lightImpact();
    // TODO: Remove member from group - stub implementation
    LoadingHelper.withLoading(
      ref: ref,
      message: 'Removing member...',
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Remove member - Coming soon')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.users, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Group not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _editGroup,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.users,
                      color: Color(0xFF0F172A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _group!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_group!.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _group!.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.userPlus,
                      label: 'Add Member',
                      onTap: _addMember,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),

            // Group Information Section
            const _Section(title: 'Group Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.users,
                    label: 'Group Name',
                    value: _group!.name,
                  ),
                  if (_group!.description != null)
                    _InfoRow(
                      icon: LucideIcons.alignLeft,
                      label: 'Description',
                      value: _group!.description!,
                    ),
                  if (_group!.teamLeaderName != null)
                    _InfoRow(
                      icon: LucideIcons.user,
                      label: 'Team Leader',
                      value: _group!.teamLeaderName!,
                    ),
                  _InfoRow(
                    icon: LucideIcons.users,
                    label: 'Member Count',
                    value: '${_group!.memberCount} member${_group!.memberCount != 1 ? "s" : ""}',
                  ),
                ],
              ),
            ),

            // Members Section
            const _Section(title: 'Members'),
            if (_members.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No members in this group',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addMember,
                        icon: const Icon(LucideIcons.userPlus, size: 18),
                        label: const Text('Add First Member'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _MemberListTile(
                    member: member,
                    onRemove: () => _removeMember(member['id']),
                  );
                },
              ),

            // Metadata Section
            const _Section(title: 'Details'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Created',
                    value: _formatDate(_group!.createdAt),
                  ),
                  if (_group!.updatedAt != null)
                    _InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Last Updated',
                      value: _formatDate(_group!.updatedAt!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF0F172A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onRemove;

  const _MemberListTile({
    required this.member,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = member['full_name'] ?? member['name'] ?? 'Unknown';
    final role = member['role'] ?? 'Member';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18),
            color: Colors.grey[500],
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Member'),
                  content: Text('Remove $fullName from this group?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onRemove();
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
