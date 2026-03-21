import 'package:flutter/material.dart';

class TextEditorPage extends StatefulWidget {
  const TextEditorPage({
    super.key,
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  final TextEditingController _controller = TextEditingController();
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('文本读取/写回接口正在接入中')));
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
              child: TextField(
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
                  hintText: '文本预览/编辑器正在接入真实读取与保存能力',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
