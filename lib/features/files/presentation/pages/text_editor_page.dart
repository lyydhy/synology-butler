import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../providers/text_editor_providers.dart';
import '../providers/code_language.dart';

class TextEditorPage extends ConsumerStatefulWidget {
  const TextEditorPage({
    super.key,
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  ConsumerState<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends ConsumerState<TextEditorPage> {
  late final CodeController _controller;
  bool _dirty = false;
  bool _saving = false;
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: getModeByFilename(widget.name),
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant TextEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _dirty = false;
      _saving = false;
      _controller.language = getModeByFilename(widget.name);
      _controller.text = '';
    }
  }

  void _onTextChanged() {
    if (_lastPath == widget.path && !_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _toggleSearch() {
    if (_controller.searchController.shouldShow) {
      _controller.searchController.hideSearch(returnFocusToCodeField: true);
    } else {
      _controller.showSearch();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));

    // 注入内容到 controller
    fileAsync.whenData((value) {
      if (_lastPath != widget.path) {
        _controller.text = value;
        _lastPath = widget.path;
      }
    });

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_dirty) return;
        final leave = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.discardChanges),
                content: Text(l10n.discardChangesHint),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
                  FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.discard)),
                ],
              ),
            ) ??
            false;
        if (leave && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          leading: IconButton(
            tooltip: '返回',
            onPressed: () async {
              if (_dirty) {
                final leave = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.discardChanges),
                        content: Text(l10n.discardChangesHint),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
                          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.discard)),
                        ],
                      ),
                    ) ??
                    false;
                if (!leave) return;
              }
              if (context.mounted) context.pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            ListenableBuilder(
              listenable: _controller.searchController,
              builder: (context, _) {
                final isSearchOpen = _controller.searchController.shouldShow;
                return IconButton(
                  tooltip: isSearchOpen ? '关闭搜索' : '搜索',
                  onPressed: _toggleSearch,
                  icon: Icon(isSearchOpen ? Icons.close : Icons.search),
                );
              },
            ),
            IconButton(
              tooltip: '预览',
              onPressed: () {
                context.push('/text-preview', extra: {
                  'path': widget.path,
                  'name': widget.name,
                });
              },
              icon: const Icon(Icons.visibility_outlined),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await ref.read(saveTextFileProvider)(widget.path, _controller.text);
                        if (!mounted) return;
                        setState(() {
                          _saving = false;
                          _dirty = false;
                        });
                        Toast.success(l10n.saveSuccess);
                        ref.invalidate(textFileProvider(widget.path));
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _saving = false);
                        Toast.error(ErrorMapper.map(e).message);
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
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
                _dirty ? '有未保存的更改' : '编辑模式',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            // 搜索打开时，用 bottom padding 把内容往上推，让搜索面板在键盘上方可见
            Expanded(
              child: fileAsync.when(
                data: (_) => CodeTheme(
                  data: codeEditorTheme,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: CodeField(
                      controller: _controller,
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(ErrorMapper.map(error).message)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
