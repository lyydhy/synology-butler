import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/text_editor_providers.dart';
import '../providers/code_language.dart';
import '../widgets/file_type_helper.dart';

class TextPreviewPage extends ConsumerStatefulWidget {
  const TextPreviewPage({
    super.key,
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  ConsumerState<TextPreviewPage> createState() => _TextPreviewPageState();
}

class _TextPreviewPageState extends ConsumerState<TextPreviewPage> {
  late final CodeLineEditingController _controller;
  String _lastPath = '';
  bool _hasSelection = false;
  String _cachedSelectedText = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController();
    _lastPath = widget.path;
    _controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSelectionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    final text = _controller.selectedText;
    final hasSelection = text.isNotEmpty;
    if (hasSelection != _hasSelection) {
      setState(() {
        _hasSelection = hasSelection;
        _cachedSelectedText = hasSelection ? text : '';
      });
    } else if (hasSelection) {
      _cachedSelectedText = text;
    }
  }

  @override
  void didUpdateWidget(covariant TextPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _hasSelection = false;
      _controller.codeLines = CodeLines.fromText('');
    }
  }

  void _copySelectedText() {
    if (_cachedSelectedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _cachedSelectedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));
    final canEdit = FileTypeHelper.isTextEditableName(widget.name) && !FileTypeHelper.isNfoName(widget.name);

    // 注入内容到 controller（每次 build 都检查，支持第二次打开同一文件）
    fileAsync.whenData((value) {
      if (_lastPath != widget.path || _controller.codeLines.toString() != value) {
        _controller.codeLines = CodeLines.fromText(value);
        _lastPath = widget.path;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: '编辑',
              onPressed: () {
                context.push('/text-editor', extra: {
                  'path': widget.path,
                  'name': widget.name,
                });
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              canEdit ? '预览模式 · 右上角可进入编辑' : '只读预览',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                fileAsync.when(
                  data: (_) => CodeEditor(
                    controller: _controller,
                    style: CodeEditorStyle(
                      fontSize: 14,
                      codeTheme: codeEditorTheme,
                    ),
                    scrollController: CodeScrollController(),
                    readOnly: true,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(ErrorMapper.map(error).message)),
                ),
                if (_hasSelection)
                  Positioned(
                    top: 8,
                    right: 16,
                    child: SafeArea(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: InkWell(
                          onTap: _copySelectedText,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '复制',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
