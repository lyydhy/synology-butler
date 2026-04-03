import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../providers/text_editor_providers.dart';

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
  final TextEditingController _controller = TextEditingController();
  bool _dirty = false;
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));

    ref.listen(textFileProvider(widget.path), (previous, next) {
      next.whenData((value) {
        if (!_initialized) {
          _controller.text = value;
          _initialized = true;
        }
      });
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
                  await ref.read(saveTextFileProvider)(widget.path, _controller.text);
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
                data: (_) => TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() => _dirty = true),
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
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
