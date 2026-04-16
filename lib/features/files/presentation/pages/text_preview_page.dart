import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/text_editor_providers.dart';
import '../providers/code_language.dart';
import '../widgets/file_type_helper.dart';
import '../widgets/copy_toolbar.dart';
import '../widgets/find_panel.dart';

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
  late final CodeFindController _findController;
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController();
    _findController = CodeFindController(_controller);
    _lastPath = widget.path;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TextPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _controller.codeLines = CodeLines.fromText('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));
    final canEdit = FileTypeHelper.isTextEditableName(widget.name) && !FileTypeHelper.isNfoName(widget.name);

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
          IconButton(
            tooltip: '搜索',
            onPressed: () => _findController.show(),
            icon: const Icon(Icons.search),
          ),
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
          CodeFindPanelView(
            controller: _findController,
            readOnly: true,
          ),
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
            child: fileAsync.when(
              data: (_) => CodeEditor(
                controller: _controller,
                findController: _findController,
                style: CodeEditorStyle(
                  fontSize: 14,
                  codeTheme: codeEditorTheme,
                ),
                scrollController: CodeScrollController(),
                readOnly: true,
                toolbarController: const PreviewToolbarController(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(ErrorMapper.map(error).message)),
            ),
          ),
        ],
      ),
    );
  }
}
