import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/api/docker_api.dart';

class ComposeProjectBuildLogsPage extends StatefulWidget {
  const ComposeProjectBuildLogsPage({
    super.key,
    required this.id,
    required this.name,
    required this.mode,
  });

  final String id;
  final String name;
  final String mode;

  @override
  State<ComposeProjectBuildLogsPage> createState() => _ComposeProjectBuildLogsPageState();
}

class _ComposeProjectBuildLogsPageState extends State<ComposeProjectBuildLogsPage> {
  final List<String> _logs = [];
  StreamSubscription<String>? _subscription;
  bool _finished = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  String get _title => widget.mode == 'stop' ? '${widget.name} 停止日志' : '${widget.name} 构建日志';

  String get _runningText => widget.mode == 'stop' ? '正在停止 Compose 项目…' : '正在构建并启动 Compose 项目…';

  String get _successText => widget.mode == 'stop' ? '停止完成' : '构建并启动完成';

  Future<void> _start() async {
    try {
      final stream = widget.mode == 'stop'
          ? DsmDockerApi().stopProjectStream(id: widget.id)
          : DsmDockerApi().buildProjectStream(id: widget.id);
      _subscription = stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _logs.addAll(chunk.split('\n').where((line) => line.trim().isNotEmpty));
            if (chunk.contains('Exit Code: 0')) {
              _finished = true;
              _success = true;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _finished = true;
            _success = false;
            _error = error.toString();
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _finished = true;
            _success = _success || _logs.any((line) => line.contains('Exit Code: 0'));
          });
        },
        cancelOnError: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _finished = true;
        _success = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLow,
            child: Text(
              _error != null
                  ? '操作失败：$_error'
                  : _finished
                      ? (_success ? _successText : '操作结束，请检查日志')
                      : _runningText,
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) => SelectableText(_logs[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
