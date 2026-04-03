import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 日志级别选项配置
class LogLevelOption {
  final String key;
  final String labelKey;
  final IconData icon;

  const LogLevelOption({
    required this.key,
    required this.labelKey,
    required this.icon,
  });
}

class TransferLogLevelPage extends ConsumerStatefulWidget {
  final String protocol;
  final String protocolName;

  const TransferLogLevelPage({
    super.key,
    required this.protocol,
    required this.protocolName,
  });

  @override
  ConsumerState<TransferLogLevelPage> createState() => _TransferLogLevelPageState();
}

class _TransferLogLevelPageState extends ConsumerState<TransferLogLevelPage> {
  Map<String, bool> _logLevels = {};
  bool _loading = true;
  bool _saving = false;

  static const _logLevelOptions = [
    LogLevelOption(key: 'create', labelKey: 'logLevelCreate', icon: Icons.add_circle_outline),
    LogLevelOption(key: 'write', labelKey: 'logLevelWrite', icon: Icons.edit),
    LogLevelOption(key: 'move', labelKey: 'logLevelMove', icon: Icons.folder),
    LogLevelOption(key: 'delete', labelKey: 'logLevelDelete', icon: Icons.delete_outline),
    LogLevelOption(key: 'read', labelKey: 'logLevelRead', icon: Icons.visibility),
    LogLevelOption(key: 'rename', labelKey: 'logLevelRename', icon: Icons.drive_file_rename_outline),
  ];

  @override
  void initState() {
    super.initState();
    _loadLogLevels();
  }

  Future<void> _loadLogLevels() async {
    try {
      final levels = await ref
          .read(systemRepositoryProvider)
          .fetchTransferLogLevel(widget.protocol);
      if (mounted) {
        setState(() {
          _logLevels = levels;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${l10n.failedToGetLogLevel}：$e');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveLogLevels() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(systemRepositoryProvider)
          .setTransferLogLevel(widget.protocol, _logLevels);
      if (mounted) {
        Toast.success(l10n.logLevelSettingsSaved);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Toast.error('${l10n.failedToSave}：$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleLogLevel(String key) {
    setState(() {
      _logLevels[key] = !(_logLevels[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.protocolName}${l10n.transferLogLevel}'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: l10n.applyChanges,
              onPressed: _saveLogLevels,
              icon: const Icon(Icons.check_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logLevels.isEmpty
              ? AppErrorState(
                  title: l10n.noData,
                  message: l10n.failedToGetLogSettings,
                  onRetry: _loadLogLevels,
                  actionLabel: l10n.retry,
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logLevelOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final option = _logLevelOptions[index];
                          final enabled = _logLevels[option.key] ?? false;
                          return _LogLevelCard(
                            option: option,
                            enabled: enabled,
                            onChanged: _toggleLogLevel,
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: FilledButton.icon(
                          onPressed: _saveLogLevels,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_saving ? l10n.saving : l10n.applyChanges),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LogLevelCard extends StatelessWidget {
  final LogLevelOption option;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _LogLevelCard({
    required this.option,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _getLabel(option.labelKey);
    final cardColor = enabled
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : theme.colorScheme.surface;

    return GestureDetector(
      onTap: () => onChanged(option.key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (enabled)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'logLevelCreate':
        return l10n.logLevelCreate;
      case 'logLevelWrite':
        return l10n.logLevelWrite;
      case 'logLevelMove':
        return l10n.logLevelMove;
      case 'logLevelDelete':
        return l10n.logLevelDelete;
      case 'logLevelRead':
        return l10n.logLevelRead;
      case 'logLevelRename':
        return l10n.logLevelRename;
      default:
        return key;
    }
  }
}
