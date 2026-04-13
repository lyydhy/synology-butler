import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/dsm_group.dart';
import '../../../../domain/entities/dsm_user.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/user_groups_providers.dart';

class UserGroupsPage extends ConsumerStatefulWidget {
  const UserGroupsPage({super.key});

  @override
  ConsumerState<UserGroupsPage> createState() => _UserGroupsPageState();
}

class _UserGroupsPageState extends ConsumerState<UserGroupsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userGroupsTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () {
              ref.invalidate(usersProvider);
              ref.invalidate(groupsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: [
                SlidingTabItem(icon: Icons.person_rounded, label: l10n.userAccountTab),
                SlidingTabItem(icon: Icons.group_rounded, label: l10n.userGroupTab),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(usersAsync: usersAsync),
          _GroupsTab(groupsAsync: groupsAsync),
        ],
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  final AsyncValue<List<DsmUser>> usersAsync;

  const _UsersTab({required this.usersAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(
        title: l10n.loadFailed(error),
        message: '$error',
        onRetry: () => ref.invalidate(usersProvider),
        actionLabel: l10n.retry,
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline_rounded, size: 52),
                const SizedBox(height: 12),
                Text(l10n.noUsers),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserCard(user: user);
          },
        );
      },
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  final AsyncValue<List<DsmGroup>> groupsAsync;

  const _GroupsTab({required this.groupsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(
        title: l10n.loadFailed(error),
        message: '$error',
        onRetry: () => ref.invalidate(groupsProvider),
        actionLabel: l10n.retry,
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 52),
                const SizedBox(height: 12),
                Text(l10n.noGroups),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _GroupCard(group: group);
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final DsmUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(user.status, user.isExpired);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showUserDetail(context, user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.description.isNotEmpty ? user.description : user.email,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(user.status, user.isExpired),
                    style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isExpired) {
    if (isExpired) return Colors.red;
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return Colors.green;
      case 'disabled':
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isExpired) {
    if (isExpired) return l10n.statusExpired;
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return l10n.statusNormal;
      case 'disabled':
      case 'suspended':
        return l10n.statusDisabled;
      default:
        return status;
    }
  }

  void _showUserDetail(BuildContext context, DsmUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _UserDetailSheet(user: user),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final DsmGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showGroupDetail(context, group),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.group_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.description.isNotEmpty ? group.description : '',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupDetail(BuildContext context, DsmGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _GroupDetailSheet(group: group),
    );
  }
}

class _UserDetailSheet extends ConsumerStatefulWidget {
  final DsmUser user;

  const _UserDetailSheet({required this.user});

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.user.description);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await ref.read(systemRepositoryProvider).updateUser(
        name: widget.user.name,
        description: _descriptionController.text,
        email: _emailController.text,
      );

      ref.invalidate(usersProvider);

      if (mounted) {
        Navigator.of(context).pop();
        Toast.success(l10n.userInfoUpdated);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${l10n.saveFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleUserStatus(bool disable) async {
    if (_saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disable ? l10n.disableUser : l10n.enableUser),
        content: Text(disable
          ? l10n.confirmDisableUser(widget.user.name)
          : l10n.confirmEnableUser(widget.user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await ref.read(systemRepositoryProvider).setUserStatus(
        name: widget.user.name,
        disabled: disable,
      );

      ref.invalidate(usersProvider);

      if (mounted) {
        Navigator.of(context).pop();
        Toast.show(disable ? l10n.userDisabled : l10n.userEnabled);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${l10n.operationFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.resetPasswordDialogTitle(widget.user.name)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final password = passwordController.text;
    if (password.isEmpty) {
      if (mounted) {
        Toast.warning(l10n.passwordCannotBeEmpty);
      }
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(systemRepositoryProvider).updateUser(
        name: widget.user.name,
        password: password,
      );

      if (mounted) {
        Toast.success(l10n.passwordResetSuccess);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${l10n.resetPasswordFailed}: $e');
      }
    } finally {
      passwordController.dispose();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.user.status, widget.user.isExpired);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Icon(Icons.person_rounded, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(widget.user.status, widget.user.isExpired),
                              style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 用户名（只读）
                    _buildReadOnlyField(
                      icon: Icons.person_outline_rounded,
                      label: l10n.userName,
                      value: widget.user.name,
                    ),
                    const SizedBox(height: 16),
                    // 描述（可编辑）
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 邮箱（可编辑）
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveChanges,
                            icon: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                            label: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 重置密码
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _resetPassword,
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: Text(l10n.resetPassword),
                    ),
                    const SizedBox(height: 12),
                    // 禁用/启用用户
                    if (widget.user.isExpired || widget.user.status.toLowerCase() == 'disabled')
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _toggleUserStatus(false),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(l10n.enableUser),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _toggleUserStatus(true),
                        icon: const Icon(Icons.block_rounded),
                        label: Text(l10n.disableUser),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField({required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool isExpired) {
    if (isExpired) return Colors.red;
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return Colors.green;
      case 'disabled':
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isExpired) {
    if (isExpired) return l10n.statusExpired;
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return l10n.statusNormal;
      case 'disabled':
      case 'suspended':
        return l10n.statusDisabled;
      default:
        return status;
    }
  }
}

class _GroupDetailSheet extends StatelessWidget {
  final DsmGroup group;

  const _GroupDetailSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.group_rounded, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.memberCount(group.memberCount),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DetailTile(
                      icon: Icons.group_outlined,
                      label: l10n.groupName,
                      value: group.name,
                    ),
                    _DetailTile(
                      icon: Icons.description_outlined,
                      label: l10n.description,
                      value: group.description.isNotEmpty ? group.description : l10n.none,
                    ),
                    
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.viewGroupMembersRequiresDsm,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
