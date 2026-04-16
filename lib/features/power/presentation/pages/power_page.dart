import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../domain/entities/power_schedule_task.dart';
import '../../../../domain/entities/power_status.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 电源状态和开关机计划合并 provider
final powerDataProvider = FutureProvider<(PowerStatus, List<PowerScheduleTask>)>((ref) async {
  final repo = ref.read(systemRepositoryProvider);
  final status = await repo.fetchPowerStatus();
  final schedule = await repo.fetchPowerSchedule();
  return (status, schedule);
});

class PowerPage extends ConsumerStatefulWidget {
  const PowerPage({super.key});

  @override
  ConsumerState<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends ConsumerState<PowerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _saving = false;

  // 本地状态
  int _ledBrightness = 3;
  String _fanSpeedMode = 'auto';
  bool _poweronBeep = false;
  bool _poweroffBeep = false;
  bool _hasChanges = false;

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

  void _loadSettings() {
    final (status, _) = ref.read(powerDataProvider).valueOrNull ?? (null, []);
    if (status != null) {
      _ledBrightness = status.ledBrightness?.brightness ?? 3;
      _fanSpeedMode = status.fanSpeed?.fanSpeedMode ?? 'auto';
      _poweronBeep = status.beepControl?.poweronBeep ?? false;
      _poweroffBeep = status.beepControl?.poweroffBeep ?? false;
    }
  }

  Future<void> _saveSettings() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await ref.read(systemRepositoryProvider).setPowerSettings(
            ledBrightness: _ledBrightness,
            fanSpeedMode: _fanSpeedMode,
            poweronBeep: _poweronBeep,
            poweroffBeep: _poweroffBeep,
          );

      ref.invalidate(powerDataProvider);
      setState(() {
        _hasChanges = false;
        _saving = false;
      });

      if (mounted) {
        Toast.success('设置已保存');
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        Toast.error('保存失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电源管理'),
        actions: [
          if (_tabController.index == 0 && _hasChanges)
            TextButton(
              onPressed: _saving ? null : _saveSettings,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
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
              tabs: const [
                SlidingTabItem(icon: Icons.settings_rounded, label: '电源设置'),
                SlidingTabItem(icon: Icons.schedule_rounded, label: '开关机计划'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SettingsTab(
            ledBrightness: _ledBrightness,
            fanSpeedMode: _fanSpeedMode,
            poweronBeep: _poweronBeep,
            poweroffBeep: _poweroffBeep,
            onChanged: () => setState(() => _hasChanges = true),
            onLedBrightnessChanged: (v) => setState(() { _ledBrightness = v; _hasChanges = true; }),
            onFanSpeedModeChanged: (v) => setState(() { _fanSpeedMode = v; _hasChanges = true; }),
            onPoweronBeepChanged: (v) => setState(() { _poweronBeep = v; _hasChanges = true; }),
            onPoweroffBeepChanged: (v) => setState(() { _poweroffBeep = v; _hasChanges = true; }),
            onLoad: _loadSettings,
          ),
          const _ScheduleTab(),
        ],
      ),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  final int ledBrightness;
  final String fanSpeedMode;
  final bool poweronBeep;
  final bool poweroffBeep;
  final VoidCallback onChanged;
  final ValueChanged<int> onLedBrightnessChanged;
  final ValueChanged<String> onFanSpeedModeChanged;
  final ValueChanged<bool> onPoweronBeepChanged;
  final ValueChanged<bool> onPoweroffBeepChanged;
  final VoidCallback onLoad;

  const _SettingsTab({
    required this.ledBrightness,
    required this.fanSpeedMode,
    required this.poweronBeep,
    required this.poweroffBeep,
    required this.onChanged,
    required this.onLedBrightnessChanged,
    required this.onFanSpeedModeChanged,
    required this.onPoweronBeepChanged,
    required this.onPoweroffBeepChanged,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerAsync = ref.watch(powerDataProvider);
    final statusAsync = powerAsync.whenData((r) => r.$1);

    // 首次加载时同步状态
    statusAsync.whenData((_) => WidgetsBinding.instance.addPostFrameCallback((_) => onLoad()));

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(powerDataProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LedBrightnessCard(
            brightness: ledBrightness,
            onChanged: onLedBrightnessChanged,
          ),
          const SizedBox(height: 12),
          _FanSpeedCard(
            mode: fanSpeedMode,
            onChanged: onFanSpeedModeChanged,
          ),
          const SizedBox(height: 12),
          _BeepControlCard(
            poweronBeep: poweronBeep,
            poweroffBeep: poweroffBeep,
            onPoweronChanged: onPoweronBeepChanged,
            onPoweroffChanged: onPoweroffBeepChanged,
          ),
          const SizedBox(height: 24),
          _InfoCard(),
        ],
      ),
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final powerAsync = ref.watch(powerDataProvider);
    final scheduleAsync = powerAsync.whenData((r) => r.$2);

    return scheduleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(powerDataProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (tasks) => tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_rounded, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无开关机计划'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) => _ScheduleTaskCard(task: tasks[index]),
            ),
    );
  }
}

class _LedBrightnessCard extends StatelessWidget {
  final int brightness;
  final ValueChanged<int> onChanged;

  const _LedBrightnessCard({required this.brightness, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.light_mode_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LED 亮度', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('调整前面板 LED 指示灯亮度', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.brightness_low, size: 20),
              Expanded(
                child: Slider(
                  value: brightness.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: brightness.toString(),
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              const Icon(Icons.brightness_high, size: 20),
            ],
          ),
          Center(child: Text('亮度: $brightness', style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _FanSpeedCard extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _FanSpeedCard({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.toys_rounded, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('风扇模式', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('调整风扇运行策略', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cool', label: Text('强力')),
              ButtonSegment(value: 'quiet', label: Text('安静')),
              ButtonSegment(value: 'auto', label: Text('自动')),
            ],
            selected: {mode},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
        ],
      ),
    );
  }
}

class _BeepControlCard extends StatelessWidget {
  final bool poweronBeep;
  final bool poweroffBeep;
  final ValueChanged<bool> onPoweronChanged;
  final ValueChanged<bool> onPoweroffChanged;

  const _BeepControlCard({
    required this.poweronBeep,
    required this.poweroffBeep,
    required this.onPoweronChanged,
    required this.onPoweroffChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.volume_up_rounded, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('蜂鸣器控制', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('开机/关机蜂鸣提示', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SwitchTile(
            title: '开机蜂鸣',
            subtitle: '开机时发出蜂鸣声',
            value: poweronBeep,
            onChanged: onPoweronChanged,
          ),
          const Divider(height: 24),
          _SwitchTile(
            title: '关机蜂鸣',
            subtitle: '关机时发出蜂鸣声',
            value: poweroffBeep,
            onChanged: onPoweroffChanged,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '部分设置可能需要重启 NAS 才能生效',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTaskCard extends StatelessWidget {
  final PowerScheduleTask task;

  const _ScheduleTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOn = task.type == PowerScheduleType.powerOn;
    final color = isOn ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOn ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      task.timeDisplay,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOn ? '开机' : '关机',
                        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!task.enabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '已禁用',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.weekdaysDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
