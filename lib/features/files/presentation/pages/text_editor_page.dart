import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _searchOpen = false;
  String _lastPath = '';
  final _searchFocusNode = FocusNode();
  final _searchTextController = TextEditingController();

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
      _searchOpen = false;
      _searchTextController.clear();
      _controller.language = getModeByFilename(widget.name);
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchTextController.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_lastPath == widget.path && !_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchTextController.clear();
    setState(() => _searchOpen = false);
  }

  void _onSearchChanged(String value) {
    final settings = _controller.searchController.settingsController.value;
    _controller.searchController.settingsController.value = settings.copyWith(
      pattern: value,
    );
    // 触发搜索
    _controller.searchController.search(
      _controller.code,
      settings: _controller.searchController.settingsController.value,
    );
    setState(() {});
  }

  void _toggleCaseSensitive() {
    final sc = _controller.searchController.settingsController;
    sc.value = sc.value.copyWith(isCaseSensitive: !sc.value.isCaseSensitive);
    _onSearchChanged(_searchTextController.text);
  }

  void _toggleRegex() {
    final sc = _controller.searchController.settingsController;
    sc.value = sc.value.copyWith(isRegExp: !sc.value.isRegExp);
    _onSearchChanged(_searchTextController.text);
  }

  void _prevMatch() {
    _controller.searchController.navigationController.movePrevious();
  }

  void _nextMatch() {
    _controller.searchController.navigationController.moveNext();
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(textFileProvider(widget.path));

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
            IconButton(
              tooltip: _searchOpen ? '关闭搜索' : '搜索',
              onPressed: _searchOpen ? _closeSearch : _openSearch,
              icon: Icon(_searchOpen ? Icons.close : Icons.search),
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
            // 自定义搜索栏（嵌在 widget 树里，跟键盘联动）
            if (_searchOpen) _buildSearchBar(),
            Expanded(
              child: fileAsync.when(
                data: (_) => CodeTheme(
                  data: codeEditorTheme,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: _searchOpen ? 0 : bottomInset),
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

  Widget _buildSearchBar() {
    final settings = _controller.searchController.settingsController.value;
    final result = _controller.fullSearchResult;
    final navState = _controller.searchController.navigationController.value;
    final current = navState.currentMatchIndex != null ? navState.currentMatchIndex! + 1 : 0;
    final total = result.matches.length;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: 6 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchTextController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '搜索...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  suffixIcon: _searchTextController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchTextController.clear();
                            _onSearchChanged('');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 大小写
          _SearchToggle(
            label: 'Aa',
            active: settings.isCaseSensitive,
            onPressed: _toggleCaseSensitive,
          ),
          const SizedBox(width: 4),
          // 正则
          _SearchToggle(
            label: '.*',
            active: settings.isRegExp,
            onPressed: _toggleRegex,
          ),
          const SizedBox(width: 4),
          // 结果计数
          SizedBox(
            width: 44,
            child: Text(
              total > 0 ? '$current/$total' : '-',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // 上一条
          IconButton(
            onPressed: total > 0 ? _prevMatch : null,
            icon: const Icon(Icons.arrow_upward, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // 下一条
          IconButton(
            onPressed: total > 0 ? _nextMatch : null,
            icon: const Icon(Icons.arrow_downward, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // 关闭
          IconButton(
            onPressed: _closeSearch,
            icon: const Icon(Icons.close, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// 搜索开关按钮
class _SearchToggle extends StatelessWidget {
  const _SearchToggle({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
