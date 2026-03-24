import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/text_editor_providers.dart';
import '../widgets/file_type_helper.dart';

class TextPreviewPage extends ConsumerWidget {
  const TextPreviewPage({
    super.key,
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fileAsync = ref.watch(textFileProvider(path));
    final canEdit = FileTypeHelper.isTextEditableName(name) && !FileTypeHelper.isNfoName(name);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: '编辑',
              onPressed: () {
                context.push('/text-editor', extra: {
                  'path': path,
                  'name': name,
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
              data: (text) => text.trim().isEmpty
                  ? Center(child: Text(l10n.notAvailableYet))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        text,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
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
