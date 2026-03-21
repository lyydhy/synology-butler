import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
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

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_dirty) return;
        final leave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('放弃修改？'),
                content: const Text('当前文件有未保存修改，确定直接返回吗？'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
                  FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('放弃')),
                ],
              ),
            ) ??
            false;
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(saveTextFileProvider)(widget.path, _controller.text);
                  if (mounted) {
                    setState(() => _dirty = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
                    ref.invalidate(textFileProvider(widget.path));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
                  }
                }
              },
              child: const Text('保存'),
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
