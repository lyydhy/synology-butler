import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../transfers/presentation/providers/transfer_providers.dart';
import '../models/shared_incoming_file.dart';

class ExternalFileUploadPage extends ConsumerStatefulWidget {
  const ExternalFileUploadPage({super.key, required this.file});

  final SharedIncomingFile file;

  @override
  ConsumerState<ExternalFileUploadPage> createState() => _ExternalFileUploadPageState();
}

class _ExternalFileUploadPageState extends ConsumerState<ExternalFileUploadPage> {
  String? _selectedRemotePath;
  String? _errorText;
  bool _isSubmitting = false;

  Future<void> _pickRemoteDirectory() async {
    final result = await context.push<String>('/files/pick-directory');
    if (!mounted || result == null || result.isEmpty) return;

    setState(() {
      _selectedRemotePath = result;
      _errorText = null;
    });
  }

  Future<void> _startUpload() async {
    if (_selectedRemotePath == null || _selectedRemotePath!.isEmpty) {
      setState(() {
        _errorText = '请先选择上传目录';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final localFile = File(widget.file.path);
      if (!await localFile.exists()) {
        throw Exception('外部文件已不可用，请重新从其他应用发起分享');
      }

      /// 外部分享得到的文件路径不一定始终有效，上传前先重新读取并校验。
      final bytes = await localFile.readAsBytes();
      await ref.read(transferControllerProvider.notifier).enqueueUpload(
            parentPath: _selectedRemotePath!,
            fileName: widget.file.name,
            bytes: Uint8List.fromList(bytes),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入上传任务')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = ErrorMapper.map(e).message;
        _isSubmitting = false;
      });
    }
  }

  String _formatSize(int? size) {
    if (size == null || size < 0) return '未知';
    const units = ['B', 'KB', 'MB', 'GB'];
    double value = size.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    final text = value >= 100 || index == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text ${units[index]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('上传到群晖')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('待上传文件', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('文件名：${widget.file.name}'),
                  const SizedBox(height: 6),
                  Text('文件大小：${_formatSize(widget.file.size)}'),
                  const SizedBox(height: 6),
                  Text('文件类型：${widget.file.mimeType ?? '未知'}'),
                  const SizedBox(height: 6),
                  Text('来源：${widget.file.source}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.targetFolder, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(_selectedRemotePath ?? '尚未选择目录'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickRemoteDirectory,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('选择上传目录'),
                  ),
                ],
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _startUpload,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(_isSubmitting ? l10n.uploading : l10n.startUpload),
          ),
        ],
      ),
    );
  }
}
