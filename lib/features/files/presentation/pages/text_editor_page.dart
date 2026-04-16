import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';

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
  late final CodeLineEditingController _controller;
  bool _dirty = false;
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromTextAsync(null);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TextEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _dirty = false;
      _controller.codeLines = CodeLines.fromText('');
    }
  }

  void _onTextChanged() {
    if (_lastPath == widget.path && !_dirty) {
      setState(() => _dirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));

    // 注入内容到 controller（每次 build 都检查）
    fileAsync.whenData((value) {
      if (_lastPath != widget.path) {
        _controller.codeLines = CodeLines.fromText(value);
        _lastPath = widget.path;
      }
    });

    final navigator = Navigator.of(context);

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
        if (!mounted || !leave) return;
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          actions: [
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
              onPressed: () async {
                try {
                  final content = _controller.codeLines.asString(TextLineBreak.lf);
                  await ref.read(saveTextFileProvider)(widget.path, content);
                  if (!mounted) return;
                  setState(() => _dirty = false);
                  Toast.success(l10n.saveSuccess);
                  ref.invalidate(textFileProvider(widget.path));
                } catch (e) {
                  if (!mounted) return;
                  Toast.error(ErrorMapper.map(e).message);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(widget.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: fileAsync.when(
                data: (_) => CodeEditor(
                  controller: _controller,
                  style: CodeEditorStyle(fontSize: 14, codeTheme: codeEditorTheme),
                  scrollController: CodeScrollController(),
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
