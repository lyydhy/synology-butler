import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/dsm_group.dart';
import '../../../../domain/entities/dsm_user.dart';
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
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户与群组'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(usersProvider);
              ref.invalidate(groupsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.colorScheme.onPrimaryContainer,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '用户账号'),
                Tab(text: '用户群组'),
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
        title: '用户列表加载失败',
        message: '$error',
        onRetry: () => ref.invalidate(usersProvider),
        actionLabel: '重试',
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 52),
                SizedBox(height: 12),
                Text('暂无用户'),
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
        title: '群组列表加载失败',
        message: '$error',
        onRetry: () => ref.invalidate(groupsProvider),
        actionLabel: '重试',
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 52),
                SizedBox(height: 12),
                Text('暂无群组'),
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
    if (isExpired) return '已过期';
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return '正常';
      case 'disabled':
      case 'suspended':
        return '已禁用';
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
                        group.description.isNotEmpty ? group.description : '${group.memberCount} 个成员',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.memberCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
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

  void _showGroupDetail(BuildContext context, DsmGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _GroupDetailSheet(group: group),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final DsmUser user;

  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(user.status, user.isExpired);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
                            user.name,
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
                              _getStatusText(user.status, user.isExpired),
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
                    _DetailTile(
                      icon: Icons.person_outline_rounded,
                      label: '用户名',
                      value: user.name,
                    ),
                    _DetailTile(
                      icon: Icons.description_outlined,
                      label: '描述',
                      value: user.description.isNotEmpty ? user.description : '无',
                    ),
                    _DetailTile(
                      icon: Icons.email_outlined,
                      label: '邮箱',
                      value: user.email.isNotEmpty ? user.email : '无',
                    ),
                    _DetailTile(
                      icon: Icons.info_outline_rounded,
                      label: '状态',
                      value: _getStatusText(user.status, user.isExpired),
                      valueColor: statusColor,
                    ),
                    if (user.isExpired)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '此用户账户已过期',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade900),
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
    if (isExpired) return '已过期';
    switch (status.toLowerCase()) {
      case 'normal':
      case 'valid':
        return '正常';
      case 'disabled':
      case 'suspended':
        return '已禁用';
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
                            '${group.memberCount} 个成员',
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
                      label: '群组名称',
                      value: group.name,
                    ),
                    _DetailTile(
                      icon: Icons.description_outlined,
                      label: '描述',
                      value: group.description.isNotEmpty ? group.description : '无',
                    ),
                    _DetailTile(
                      icon: Icons.people_outline_rounded,
                      label: '成员数量',
                      value: '${group.memberCount} 人',
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
                              '查看群组成员列表需要在 DSM Web 界面中操作',
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
  final Color? valueColor;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
