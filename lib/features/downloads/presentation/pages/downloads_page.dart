import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/download_status_helper.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_detail_sheet.dart';

/// 下载任务页面。
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  // Tab 索引对应: 0=全部 1=下载中 2=已暂停 3=已完成
  // 状态代码: 2=下载中 3=暂停 5=完成 8=做种
  static const _statusCodes = ['2', '3', '5', '8'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DownloadTask> _filterTasks(List<DownloadTask> tasks, int page) {
    if (page == 0) return tasks; // 全部
    final targetCode = _statusCodes[page - 1];
    if (page == 3) {
      // 已完成 tab: status=5(finished) 或 status=8(seeding)
      return tasks.where((t) => t.status == '5' || t.status == '8').toList();
    }
    return tasks.where((t) => t.status == targetCode).toList();
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.createDownloadTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: l10n.downloadLinkOrMagnet),
                maxLines: 3,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final uri = controller.text.trim();
                      if (uri.isEmpty) {
                        setState(() => errorText = l10n.downloadLinkOrMagnet);
                        return;
                      }
                      setState(() {
                        isSubmitting = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(downloadActionProvider)(uri);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        setState(() {
                          errorText = ErrorMapper.map(e).message;
                          isSubmitting = false;
                        });
                      }
                    },
              child: Text(isSubmitting ? l10n.submitting : l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTaskAction(BuildContext context, DownloadTask task, String action) async {
    try {
      if (action == 'detail') {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => DownloadTaskDetailSheet(task: task),
        );
        return;
      }
      if (action == 'pause') {
        await ref.read(downloadPauseProvider)(task.id);
      } else if (action == 'resume') {
        await ref.read(downloadResumeProvider)(task.id);
      } else if (action == 'delete') {
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteTask),
                content: Text('${task.title}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.deleteConfirm),
                  ),
                ],
              ),
            ) ??
            false;
        if (!confirmed) return;
        await ref.read(downloadDeleteProvider)(task.id);
      }
      if (context.mounted) {
        Toast.success(l10n.operationSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(ErrorMapper.map(e).message);
      }
    }
  }

  Future<void> _refreshTasks() async {
    ref.invalidate(downloadListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final currentSession = connection.session;

    if (currentServer == null || currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.downloadsTitle)),
        body: Center(child: Text(l10n.noSessionPleaseLogin)),
      );
    }

    final availableAsync = ref.watch(downloadStationAvailableProvider);

    return availableAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.downloadsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _NotInstalledView(onRetry: () => ref.invalidate(downloadStationAvailableProvider)),
      data: (available) {
        if (!available) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.downloadsTitle)),
            body: _NotInstalledView(onRetry: () => ref.invalidate(downloadStationAvailableProvider)),
          );
        }
        return _DownloadScaffold(
          pageController: _pageController,
          currentPage: _currentPage,
          onPageChanged: (page) => setState(() => _currentPage = page),
          filterTasks: (tasks, page) => _filterTasks(tasks, page),
          onRefresh: _refreshTasks,
          onShowAddDialog: () => _showAddTaskDialog(context),
          onHandleAction: (task, action) => _handleTaskAction(context, task, action),
          tasksAsync: ref.watch(downloadListProvider),
        );
      },
    );
  }
}

class _NotInstalledView extends StatelessWidget {
  const _NotInstalledView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text('Download Station ${l10n.notInstalled}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '请在群晖 NAS 上安装 Download Station 套件',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _DownloadScaffold extends ConsumerWidget {
  const _DownloadScaffold({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.filterTasks,
    required this.onRefresh,
    required this.onShowAddDialog,
    required this.onHandleAction,
    required this.tasksAsync,
  });

  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final List<DownloadTask> Function(List<DownloadTask>, int) filterTasks;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowAddDialog;
  final Future<void> Function(DownloadTask, String) onHandleAction;
  final AsyncValue<List<DownloadTask>> tasksAsync;

  static const _tabIcons = [
    Icons.list_alt,
    Icons.downloading,
    Icons.pause_circle_outline,
    Icons.check_circle_outline,
  ];
  static const _tabLabels = ['全部', '下载中', '已暂停', '已完成'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SlidingTabBar(
              pageController: pageController,
              tabs: List.generate(
                4,
                (i) => SlidingTabItem(icon: _tabIcons[i], label: _tabLabels[i]),
              ),
              height: 48,
              iconSize: 18,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: onPageChanged,
              children: [
                _buildTaskListPage(context, ref, 0),
                _buildTaskListPage(context, ref, 1),
                _buildTaskListPage(context, ref, 2),
                _buildTaskListPage(context, ref, 3),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onShowAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskListPage(BuildContext context, WidgetRef ref, int page) {
    final theme = Theme.of(context);

    return tasksAsync.when(
      data: (tasks) {
        final visibleTasks = filterTasks(tasks, page);
        if (visibleTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noTasksForFilter,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: visibleTasks.length,
            itemBuilder: (context, index) {
              final task = visibleTasks[index];
              return _DownloadTaskCard(
                task: task,
                onTap: () => onHandleAction(task, 'detail'),
                onAction: (action) => onHandleAction(task, action),
              );
            },
          ),
        );
      },
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                '${l10n.downloadTasksLoadFailed}\n${ErrorMapper.map(error).message}',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

IconData _iconForFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return Icons.insert_drive_file_outlined;
  final ext = name.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'bmp':
    case 'ico':
      return Icons.image_outlined;
    case 'mp4':
    case 'mkv':
    case 'avi':
    case 'mov':
    case 'wmv':
    case 'flv':
      return Icons.movie_outlined;
    case 'mp3':
    case 'flac':
    case 'wav':
    case 'm4a':
    case 'aac':
    case 'ogg':
      return Icons.audio_file_outlined;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
    case 'bz2':
      return Icons.archive_outlined;
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
    case 'xls':
    case 'xlsx':
    case 'ppt':
    case 'pptx':
      return Icons.description_outlined;
    case 'torrent':
      return Icons.bug_report_outlined;
    case 'txt':
    case 'log':
    case 'nfo':
    case 'md':
      return Icons.article_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

/// 任务卡片
class _DownloadTaskCard extends StatelessWidget {
  const _DownloadTaskCard({
    required this.task,
    required this.onTap,
    required this.onAction,
  });

  final DownloadTask task;
  final VoidCallback onTap;
  final Future<void> Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBadge = _buildStatusBadge(context, task.status);
    final isPaused = task.status == '3';
    final isFinished = task.status == '5' || task.status == '8';
    final isError = task.status == '101';
    final isDownloading = DownloadStatusHelper.isDownloading(task.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 文件类型图标
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForFileName(task.title),
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          statusBadge,
                        ],
                      ),
                    ),
                    // 右侧进度或操作按钮
                    if (!isFinished && !isError)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(task.progress * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => onAction(isPaused ? 'resume' : 'pause'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaused
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaused ? Icons.play_arrow : Icons.pause,
                                    size: 14,
                                    color: isPaused
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isPaused ? l10n.resume : l10n.pause,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPaused
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isFinished)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 28,
                      ),
                    if (isError)
                      Icon(
                        Icons.error,
                        color: theme.colorScheme.error,
                        size: 28,
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: onAction,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'detail',
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.detail),
                            ],
                          ),
                        ),
                        if (!isFinished && !isError)
                          PopupMenuItem(
                            value: isPaused ? 'resume' : 'pause',
                            child: Row(
                              children: [
                                Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                                const SizedBox(width: 8),
                                Text(isPaused ? l10n.resume : l10n.pause),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Text(l10n.deleteConfirm, style: TextStyle(color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!isFinished && !isError) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress.clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final (color, bgColor, text) = _statusStyle(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, Color, String) _statusStyle(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status) {
      case '1':
        return (Colors.white, Colors.orange.shade600, l10n.downloadStatusWaiting);
      case '2': // downloading
        return (Colors.white, Colors.blue.shade600, l10n.downloadStatusDownloading);
      case '3': // paused
        return (Colors.white, Colors.amber.shade700, l10n.downloadStatusPaused);
      case '4': // finishing
        return (Colors.white, Colors.teal.shade600, l10n.downloadStatusFinishing);
      case '5': // finished
        return (Colors.white, Colors.green.shade600, l10n.downloadStatusFinished);
      case '6': // hash_checking
        return (Colors.white, Colors.purple.shade600, l10n.downloadStatusHashChecking);
      case '7': // pre-seeding
        return (Colors.white, Colors.teal.shade400, l10n.downloadStatusPreSeeding);
      case '8': // seeding
        return (Colors.white, Colors.teal.shade600, l10n.downloadStatusSeeding);
      case '9': // filehosting_waiting
        return (Colors.white, Colors.deepOrange.shade600, l10n.downloadStatusFileHostingWaiting);
      case '10': // extracting
        return (Colors.white, Colors.indigo.shade600, l10n.downloadStatusExtracting);
      case '11': // preprocessing
        return (Colors.white, Colors.blueGrey.shade600, l10n.downloadStatusPreprocessing);
      case '13': // downloaded
        return (Colors.white, Colors.green.shade400, l10n.downloadStatusDownloaded);
      case '14': // postprocessing
        return (Colors.white, Colors.purple.shade400, l10n.downloadStatusPostProcessing);
      case '15': // captcha_needed
        return (Colors.white, Colors.red.shade700, l10n.downloadStatusCaptchaNeeded);
      default:
        // 101+ error
        if (int.tryParse(status) != null && int.parse(status) >= 101) {
          return (Colors.white, theme.colorScheme.error, l10n.downloadStatusError);
        }
        return (theme.colorScheme.onSurfaceVariant, theme.colorScheme.surfaceContainerHighest, l10n.downloadStatusUnknown);
    }
  }
}
