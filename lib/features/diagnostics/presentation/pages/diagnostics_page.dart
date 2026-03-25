import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../downloads/presentation/providers/download_providers.dart';
import '../../../files/presentation/providers/file_providers.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  String authResult = '未测试';
  String fileResult = '未测试';
  String downloadResult = '未测试';
  bool loadingAuth = false;
  bool loadingFile = false;
  bool loadingDownload = false;

  Future<void> testAuth() async {
    setState(() => loadingAuth = true);
    try {
      final server = ref.read(activeServerProvider);
      final session = ref.read(activeSessionProvider);
      if (server == null || session == null) throw Exception('当前没有可用会话');
      setState(() => authResult = '成功：已存在当前设备与会话');
    } catch (e) {
      setState(() => authResult = '失败：${ErrorMapper.map(e).message}');
    } finally {
      if (mounted) setState(() => loadingAuth = false);
    }
  }

  Future<void> testFiles() async {
    setState(() => loadingFile = true);
    try {
      final files = await ref.read(fileListProvider.future);
      setState(() => fileResult = '成功：读取到 ${files.length} 个文件项');
    } catch (e) {
      setState(() => fileResult = '失败：${ErrorMapper.map(e).message}');
    } finally {
      if (mounted) setState(() => loadingFile = false);
    }
  }

  Future<void> testDownloads() async {
    setState(() => loadingDownload = true);
    try {
      final tasks = await ref.read(downloadListProvider.future);
      setState(() => downloadResult = '成功：读取到 ${tasks.length} 个下载任务');
    } catch (e) {
      setState(() => downloadResult = '失败：${ErrorMapper.map(e).message}');
    } finally {
      if (mounted) setState(() => loadingDownload = false);
    }
  }

  Widget buildCard({
    required String title,
    required String result,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(result),
        trailing: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton(
                onPressed: onTap,
                child: const Text('测试'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模块诊断')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildCard(title: '认证状态', result: authResult, loading: loadingAuth, onTap: testAuth),
          buildCard(title: '文件模块', result: fileResult, loading: loadingFile, onTap: testFiles),
          buildCard(title: '下载模块', result: downloadResult, loading: loadingDownload, onTap: testDownloads),
          const SizedBox(height: 16),
          const ListTile(
            title: Text('说明'),
            subtitle: Text('这些测试用于快速判断当前会话、文件接口和下载接口是否已经联通。'),
          ),
        ],
      ),
    );
  }
}
