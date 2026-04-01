import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/terminal_settings.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 终端设置 Provider
final terminalSettingsProvider = FutureProvider<TerminalSettings>((ref) async {
  return ref.read(systemRepositoryProvider).fetchTerminalSettings();
});

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  late TextEditingController _portController;
  bool _sshEnabled = false;
  bool _telnetEnabled = false;
  bool _hasChanges = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(text: '22');
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  void _updateFromSettings(TerminalSettings settings) {
    _sshEnabled = settings.sshEnabled;
    _telnetEnabled = settings.telnetEnabled;
    _portController.text = settings.sshPort.toString();
    _hasChanges = false;
  }

  Future<void> _saveSettings() async {
    if (_saving) return;

    final port = int.tryParse(_portController.text);
    if (port == null || port < 1 || port > 65535) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的端口号 (1-65535)')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(systemRepositoryProvider).setTerminalSettings(
            sshEnabled: _sshEnabled,
            telnetEnabled: _telnetEnabled,
            sshPort: port,
          );

      ref.invalidate(terminalSettingsProvider);
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
    final settingsAsync = ref.watch(terminalSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('终端设置'),
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
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(terminalSettingsProvider),
          actionLabel: '重试',
        ),
        data: (settings) {
          // 首次加载时同步状态
          if (!_hasChanges) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateFromSettings(settings);
              if (mounted) setState(() {});
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SSH 设置
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
                          child: Icon(Icons.terminal_rounded, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SSH',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '安全外壳协议，用于远程命令行访问',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _sshEnabled,
                          onChanged: (value) {
                            setState(() {
                              _sshEnabled = value;
                              _hasChanges = true;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_sshEnabled) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'SSH 端口',
                          border: OutlineInputBorder(),
                          helperText: '默认端口: 22',
                        ),
                        onChanged: (_) => setState(() => _hasChanges = true),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Telnet 设置
              Container(
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
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.computer_rounded, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Telnet',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '远程终端协议（不安全，建议关闭）',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _telnetEnabled,
                      onChanged: (value) {
                        setState(() {
                          _telnetEnabled = value;
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
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '启用终端服务可能会带来安全风险，请确保设置了强密码并限制访问权限',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
