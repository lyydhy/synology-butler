import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/share_link.dart';
import '../providers/file_providers.dart';

class ShareLinkPage extends ConsumerStatefulWidget {
  const ShareLinkPage({
    super.key,
    required this.path,
    this.existingLink,
  });

  /// 文件路径
  final String path;

  /// 已存在的分享链接（用于编辑）
  final ShareLinkResult? existingLink;

  @override
  ConsumerState<ShareLinkPage> createState() => _ShareLinkPageState();
}

class _ShareLinkPageState extends ConsumerState<ShareLinkPage> {
  ShareLinkResult? _link;
  bool _loading = true;
  String? _error;

  DateTime? _expireDate;
  final _expireTimesController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.existingLink != null) {
      _link = widget.existingLink;
      _loading = false;
      _parseExistingLink();
    } else {
      _createLink();
    }
  }

  void _parseExistingLink() {
    if (_link?.dateExpired != null && _link!.dateExpired!.isNotEmpty) {
      try {
        _expireDate = DateTime.parse(_link!.dateExpired!);
      } catch (_) {}
    }
    if (_link != null && _link!.expireTimes > 0) {
      _expireTimesController.text = _link!.expireTimes.toString();
    }
  }

  Future<void> _createLink() async {
    try {
      final result = await ref.read(fileShareProvider)(
        widget.path,
        dateExpired: _expireDate?.toIso8601String(),
        expireTimes: int.tryParse(_expireTimesController.text) ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _link = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_link == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(fileStationApiProvider);
      await api.editShareLink(
        shareId: _link!.id,
        url: _link!.url,
        path: _link!.path,
        dateExpired: _expireDate?.toIso8601String(),
        expireTimes: int.tryParse(_expireTimesController.text) ?? 0,
      );
      if (!mounted) return;
      Toast.success(l10n.shareLinkSaveSuccess);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Toast.error(ErrorMapper.map(e).message);
    }
  }

  @override
  void dispose() {
    _expireTimesController.dispose();
    super.dispose();
  }

  String get _formatExpireDate {
    if (_expireDate == null) return l10n.shareLinkNoLimit;
    return '${_expireDate!.year}-${_expireDate!.month.toString().padLeft(2, '0')}-${_expireDate!.day.toString().padLeft(2, '0')} '
        '${_expireDate!.hour.toString().padLeft(2, '0')}:${_expireDate!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickExpireDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expireDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expireDate ?? now),
    );
    if (!mounted) return;
    setState(() {
      _expireDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareLinkCreate),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _createLink();
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 文件名
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _link?.name ?? widget.path.split('/').last,
                                style: theme.textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 分享链接 + 复制
                      Text(l10n.shareLink, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _link?.url ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              tooltip: l10n.copy,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _link?.url ?? ''));
                                Toast.success(l10n.shareLinkCopied);
                              },
                            ),
                          ],
                        ),
                      ),

                      // 二维码
                      if (_link?.qrcode != null && _link!.qrcode!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.memory(
                              Base64Decoder().convert(_link!.qrcode!.split(',').last),
                              width: 160,
                              height: 160,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 过期时间
                      Text(l10n.shareLinkExpireDate, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickExpireDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_formatExpireDate)),
                              if (_expireDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () => setState(() => _expireDate = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 访问次数
                      Text(l10n.shareLinkAccessCount, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(l10n.shareLinkAccessCountHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _expireTimesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: '0',
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 保存按钮
                      FilledButton(
                        onPressed: _loading ? null : _saveChanges,
                        child: Text(l10n.shareLinkSaveChanges),
                      ),
                    ],
                  ),
                ),
    );
  }
}

