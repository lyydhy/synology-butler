import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/power_status.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 电源状态 Provider
final powerStatusProvider = FutureProvider<PowerStatus>((ref) async {
  return ref.read(systemRepositoryProvider).fetchPowerStatus();
});

class PowerPage extends ConsumerStatefulWidget {
  const PowerPage({super.key});

  @override
  ConsumerState<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends ConsumerState<PowerPage> {
  bool _saving = false;

  // 本地状态
  int _ledBrightness = 3;
  String _fanSpeedMode = 'auto';
  bool _poweronBeep = false;
  bool _poweroffBeep = false;
  bool _hasChanges = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  void _loadSettings() {
    final status = ref.read(powerStatusProvider).valueOrNull;
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

      ref.invalidate(powerStatusProvider);
      setState(() {
        _hasChanges = false;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(powerStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('电源管理'),
        actions: [
          if (_hasChanges)
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
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(powerStatusProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // LED 亮度
            Container(
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
                            Text(
                              'LED 亮度',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '调整 NAS 前面板 LED 指示灯亮度',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
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
                          value: _ledBrightness.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _ledBrightness.toString(),
                          onChanged: (value) {
                            setState(() {
                              _ledBrightness = value.round();
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.brightness_high, size: 20),
                    ],
                  ),
                  Center(
                    child: Text(
                      '亮度: $_ledBrightness',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 风扇模式
            Container(
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
                            Text(
                              '风扇模式',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '调整风扇运行策略',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'cool', label: Text('强力散热')),
                      ButtonSegment(value: 'quiet', label: Text('安静模式')),
                      ButtonSegment(value: 'auto', label: Text('自动')),
                    ],
                    selected: {_fanSpeedMode},
                    onSelectionChanged: (value) {
                      setState(() {
                        _fanSpeedMode = value.first;
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 蜂鸣器控制
            Container(
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
                            Text(
                              '蜂鸣器控制',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '开机/关机蜂鸣提示',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SwitchTile(
                    title: '开机蜂鸣',
                    subtitle: '开机时发出蜂鸣声',
                    value: _poweronBeep,
                    onChanged: (value) {
                      setState(() {
                        _poweronBeep = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  _SwitchTile(
                    title: '关机蜂鸣',
                    subtitle: '关机时发出蜂鸣声',
                    value: _poweroffBeep,
                    onChanged: (value) {
                      setState(() {
                        _poweroffBeep = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 安全提示
            Container(
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
            ),
          ],
        ),
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
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
