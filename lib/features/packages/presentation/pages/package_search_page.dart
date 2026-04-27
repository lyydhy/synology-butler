import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../domain/entities/package_item.dart';
import 'packages_page.dart';

class PackageSearchPage extends ConsumerStatefulWidget {
  const PackageSearchPage({super.key, required this.packages});

  final List<PackageItem> packages;

  @override
  ConsumerState<PackageSearchPage> createState() => _PackageSearchPageState();
}

class _PackageSearchPageState extends ConsumerState<PackageSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<PackageItem> get _filtered {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.packages.where((item) {
      return item.displayName.toLowerCase().contains(q) ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索套件',
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: (_) {},
        ),
      ),
      body: _filtered.isEmpty
          ? AppEmptyState(
              message: _query.isEmpty ? '输入关键词搜索套件' : '未找到相关套件',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => PackageCard(item: _filtered[index]),
            ),
    );
  }
}
