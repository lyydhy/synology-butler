import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/api/docker_api.dart';

class ComposeProjectCreatePage extends StatefulWidget {
  const ComposeProjectCreatePage({super.key});

  @override
  State<ComposeProjectCreatePage> createState() => _ComposeProjectCreatePageState();
}

class _ComposeProjectCreatePageState extends State<ComposeProjectCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sharePathController = TextEditingController(text: '/docker/');
  final _yamlController = TextEditingController(
    text: 'name: openclaw-test\n\nservices:\n  whoami:\n    image: traefik/whoami:v1.10\n    container_name: openclaw-test-whoami\n    restart: unless-stopped\n    ports:\n      - "18080:80"\n',
  );
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sharePathController.dispose();
    _yamlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final result = await DsmDockerApi().createProject(
        DockerComposeCreateRequest(
          name: _nameController.text.trim(),
          sharePath: _sharePathController.text.trim(),
          content: _yamlController.text,
        ),
      );
      if (!mounted) return;
      context.pop(true);
      context.push(
        '/container-management/compose-detail',
        extra: {'id': result.id, 'name': result.name},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('创建 Compose 项目失败：$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建 Compose 项目')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '项目名称', border: OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty ? '请输入项目名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sharePathController,
              decoration: const InputDecoration(labelText: '共享路径', border: OutlineInputBorder()),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return '请输入共享路径';
                if (!text.startsWith('/')) return '共享路径必须以 / 开头';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _yamlController,
              minLines: 16,
              maxLines: 24,
              decoration: const InputDecoration(
                labelText: 'docker-compose.yml',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? '请输入 YAML 内容' : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(_submitting ? '创建中' : '创建项目'),
            ),
          ],
        ),
      ),
    );
  }
}
