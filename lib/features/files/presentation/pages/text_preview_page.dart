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

class _TextPreviewPageState extends ConsumerState<TextPreviewPage> {
  late final CodeController _controller;
  bool _searchOpen = false;
  String _lastPath = '';
  String _lastContent = '';
  final _searchFocusNode = FocusNode();
  final _searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: getModeByFilename(widget.name),
    );
    _lastPath = widget.path;
  }

  @override
  void didUpdateWidget(covariant TextPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _lastPath = widget.path;
      _lastContent = '';
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
    _controller.dispose();
    super.dispose();
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
    final canEdit = FileTypeHelper.isTextEditableName(widget.name) && !FileTypeHelper.isNfoName(widget.name);

    fileAsync.whenData((value) {
      if (_lastPath != widget.path || _lastContent != value) {
        _controller.text = value;
        _lastContent = value;
        _lastPath = widget.path;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            tooltip: _searchOpen ? '关闭搜索' : '搜索',
            onPressed: _searchOpen ? _closeSearch : _openSearch,
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
          ),
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
          if (_searchOpen) _buildSearchBar(context),
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

  Widget _buildSearchBar(BuildContext context) {
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
          _SearchToggle(
            label: 'Aa',
            active: settings.isCaseSensitive,
            onPressed: _toggleCaseSensitive,
          ),
          const SizedBox(width: 4),
          _SearchToggle(
            label: '.*',
            active: settings.isRegExp,
            onPressed: _toggleRegex,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: Text(
              total > 0 ? '$current/$total' : '-',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: total > 0 ? _prevMatch : null,
            icon: const Icon(Icons.arrow_upward, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: total > 0 ? _nextMatch : null,
            icon: const Icon(Icons.arrow_downward, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
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
