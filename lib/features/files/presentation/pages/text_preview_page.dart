import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
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
  late final CodeController _controller;
  String _lastPath = '';
  String _lastContent = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: getModeByFilename(widget.name),
    );
    _lastPath = widget.path;
  }

  @override
  void didUpdateWidget(covariant TextPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _lastContent = '';
      _controller.language = getModeByFilename(widget.name);
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));
    final canEdit = FileTypeHelper.isTextEditableName(widget.name) && !FileTypeHelper.isNfoName(widget.name);

    // 注入内容到 controller（支持同一文件第二次打开）
    fileAsync.whenData((value) {
      if (_lastPath != widget.path || _lastContent != value) {
        _controller.text = value;
        _lastContent = value;
        _lastPath = widget.path;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: () => _controller.showSearch(),
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
              data: (_) => CodeTheme(
                data: codeEditorTheme,
                child: CodeField(
                  controller: _controller,
                  readOnly: true,
                ),
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
