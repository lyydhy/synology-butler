import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../domain/entities/transfer_task.dart';
import '../core/utils/local_app_logger.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/dashboard/presentation/providers/dashboard_realtime_global.dart';
import '../features/external_share/models/shared_incoming_file.dart';
import '../features/external_share/services/external_share_pending_store.dart';
import '../features/external_share/services/external_share_service.dart';
import '../features/preferences/providers/preferences_providers.dart';
import '../features/transfers/presentation/providers/transfer_providers.dart';
import '../features/transfers/presentation/providers/transfer_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

final _botToastBuilder = BotToastInit();

class QunhuiManagerApp extends ConsumerStatefulWidget {
  const QunhuiManagerApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  ConsumerState<QunhuiManagerApp> createState() => _QunhuiManagerAppState();
}

class _QunhuiManagerAppState extends ConsumerState<QunhuiManagerApp> {
  StreamSubscription? _externalShareSubscription;
  final ExternalSharePendingStore _pendingStore = const ExternalSharePendingStore();
  late final _router = createAppRouter(initialLocation: widget.initialLocation);

  // 用于追踪上一次的下载任务状态
  Map<String, TransferTaskStatus> _lastDownloadStatuses = {};

  @override
  void initState() {
    super.initState();
    _externalShareSubscription = ExternalShareService.instance.watchIncomingFiles().listen((file) async {
      await _handleIncomingShare(file);
    }, onError: (_) {});

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final file = await ExternalShareService.instance.getInitialSharedFile();
      await ExternalShareService.instance.reset();
      if (mounted && file != null) {
        await _handleIncomingShare(file);
      }
    });

  }

  Future<void> _handleIncomingShare(SharedIncomingFile file) async {
    await ExternalShareService.instance.reset();
    if (!mounted) return;

    /// 分享拉起时先只做暂存，真正的跳转统一交给 Splash 恢复完成后决定，
    /// 避免和启动时的默认导航互相覆盖。
    await _pendingStore.save(file);
  }

  void _handleDownloadCompleted(DownloadCompletedEvent event) {
    // bd 插件会自动显示通知，这里无需额外处理
    // 事件保留用于其他依赖完成状态的逻辑
  }

  @override
  void dispose() {
    _externalShareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(restorePreferencesProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? AppThemeModeOption.system;
    final themeColor = ref.watch(themeColorProvider).valueOrNull ?? AppThemeColorOption.blue;
    final localeOption = ref.watch(localeProvider).valueOrNull ?? AppLocaleOption.system;
    final _ = ref.watch(recoverSessionProvider);
    ref.watch(globalRealtimeOverviewProvider);
    final seedColor = seedColorFor(themeColor);

    // 全局监听下载任务状态变化
    ref.listenManual<List<TransferTask>>(transferProvider, (previous, next) {
      if (previous == null) {
        // 首次加载，记录当前状态但不触发事件
        _lastDownloadStatuses = {
          for (final task in next)
            if (task.type == TransferTaskType.download) task.id: task.status
        };
        return;
      }

      final newCompleted = <TransferTask>[];
      for (final task in next) {
        if (task.type != TransferTaskType.download) continue;
        if (task.status != TransferTaskStatus.success) continue;

        final lastStatus = _lastDownloadStatuses[task.id];
        // 只有从 running -> success 才触发
        if (lastStatus == TransferTaskStatus.running) {
          newCompleted.add(task);
        }
      }

      // 更新状态记录
      _lastDownloadStatuses = {
        for (final task in next)
          if (task.type == TransferTaskType.download) task.id: task.status
      };

      // 触发第一个完成事件
      if (newCompleted.isNotEmpty) {
        final task = newCompleted.first;
        ref.read(downloadCompletedProvider.notifier).state = DownloadCompletedEvent(
          taskId: task.id,
          fileName: task.title,
          filePath: task.targetPath,
          completedAt: DateTime.now(),
        );
      }
    });

    // 监听下载完成事件，弹出 SnackBar
    ref.listenManual<DownloadCompletedEvent?>(downloadCompletedProvider, (previous, next) {
      if (next != null) {
        _handleDownloadCompleted(next);
        // 清除事件，避免重复消费
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(downloadCompletedProvider.notifier).state = null;
        });
      }
    });

    return MaterialApp.router(
      title: '群晖管家',
      theme: AppTheme.light(seedColor),
      darkTheme: AppTheme.dark(seedColor),
      themeMode: themeModeFor(themeMode),
      locale: localeFor(localeOption),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      routerConfig: _router,
      builder: (context, child) => _botToastBuilder(context, child),
      debugShowCheckedModeBanner: false,
    );
  }
}
