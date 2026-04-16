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

class _TextPreviewPageState extends ConsumerState<TextPreviewPage>
    with WidgetsBindingObserver {
  late final CodeController _controller;
  String _lastPath = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: getModeByFilename(widget.name),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TextPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _initialized = false;
      _controller.language = getModeByFilename(widget.name);
      _controller.text = '';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从编辑页保存后返回预览，provider 被 invalidate 了但 widget 没变化，
    // 通过 app lifecycle 重新进入时主动刷新内容
    if (state == AppLifecycleState.resumed && _lastPath == widget.path && _initialized) {
      ref.invalidate(textFileProvider(widget.path));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));
    final canEdit = FileTypeHelper.isTextEditableName(widget.name) && !FileTypeHelper.isNfoName(widget.name);

    // 监听 provider 数据变化，自动同步到 controller
    fileAsync.whenData((value) {
      _controller.text = value;
      _lastPath = widget.path;
      _initialized = true;
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
