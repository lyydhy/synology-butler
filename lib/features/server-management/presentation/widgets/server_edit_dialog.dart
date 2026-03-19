import 'package:flutter/material.dart';

import '../../../../domain/entities/nas_server.dart';

class ServerEditDialog extends StatefulWidget {
  const ServerEditDialog({
    super.key,
    required this.server,
  });

  final NasServer server;

  @override
  State<ServerEditDialog> createState() => _ServerEditDialogState();
}

class _ServerEditDialogState extends State<ServerEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController hostController;
  late final TextEditingController portController;
  late final TextEditingController basePathController;
  late bool https;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.server.name);
    hostController = TextEditingController(text: widget.server.host);
    portController = TextEditingController(text: widget.server.port.toString());
    basePathController = TextEditingController(text: widget.server.basePath ?? '');
    https = widget.server.https;
  }

  @override
  void dispose() {
    nameController.dispose();
    hostController.dispose();
    portController.dispose();
    basePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑设备'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '设备名称')),
            const SizedBox(height: 12),
            TextField(controller: hostController, decoration: const InputDecoration(labelText: '地址 / 域名 / IP')),
            const SizedBox(height: 12),
            TextField(controller: portController, decoration: const InputDecoration(labelText: '端口')),
            const SizedBox(height: 12),
            TextField(controller: basePathController, decoration: const InputDecoration(labelText: '基础路径（可选）')),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: https,
              onChanged: (value) => setState(() => https = value),
              title: const Text('使用 HTTPS'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              NasServer(
                id: '${hostController.text.trim()}:${portController.text.trim()}:${basePathController.text.trim()}',
                name: nameController.text.trim().isEmpty ? widget.server.name : nameController.text.trim(),
                host: hostController.text.trim(),
                port: int.tryParse(portController.text.trim()) ?? widget.server.port,
                https: https,
                basePath: basePathController.text.trim().isEmpty ? null : basePathController.text.trim(),
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
