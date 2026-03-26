import 'package:flutter/material.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../data/api/docker_api.dart';

class ContainerDetailPage extends StatefulWidget {
  const ContainerDetailPage({super.key, required this.name});

  final String name;

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<DockerContainerDetail> _detailFuture;
  late Future<List<String>> _logDatesFuture;
  String? _selectedDate;
  Future<List<String>>? _logsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _detailFuture = DsmDockerApi().fetchContainerDetail(name: widget.name);
    _logDatesFuture = DsmDockerApi().fetchContainerLogDates(name: widget.name);
  }

  void _refresh() {
    setState(() {
      _detailFuture = DsmDockerApi().fetchContainerDetail(name: widget.name);
      _logDatesFuture = DsmDockerApi().fetchContainerLogDates(name: widget.name);
      if (_selectedDate != null) {
        _logsFuture = DsmDockerApi().fetchContainerLogs(name: widget.name, date: _selectedDate!);
      }
    });
  }

  void _selectDate(String value) {
    setState(() {
      _selectedDate = value;
      _logsFuture = DsmDockerApi().fetchContainerLogs(name: widget.name, date: value);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SlidingTabBar(
              tabController: _tabController,
              tabs: const [
                SlidingTabItem(icon: Icons.info_outline_rounded, label: '详情'),
                SlidingTabItem(icon: Icons.receipt_long_outlined, label: '日志'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<DockerContainerDetail>(
                  future: _detailFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _DetailErrorState(onRetry: _refresh);
                    }
                    final detail = snapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SectionCard(
                          title: '基础信息',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('状态：${detail.status}'),
                              const SizedBox(height: 8),
                              Text('命令：${detail.command.isEmpty ? '--' : detail.command}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: '端口',
                          child: detail.ports.isEmpty
                              ? const Text('暂无端口绑定')
                              : Column(
                                  children: detail.ports
                                      .map((port) => _KeyValueLine(
                                            left: (port['host_port'] ?? '--').toString(),
                                            right: (port['container_port'] ?? '--').toString(),
                                            extra: (port['type'] ?? '--').toString(),
                                          ))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: '挂载卷',
                          child: detail.volumes.isEmpty
                              ? const Text('暂无卷绑定')
                              : Column(
                                  children: detail.volumes
                                      .map((volume) => _KeyValueLine(
                                            left: (volume['host_volume_file'] ?? '--').toString(),
                                            right: (volume['mount_point'] ?? '--').toString(),
                                            extra: (volume['type'] ?? '--').toString(),
                                          ))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: '环境变量',
                          child: detail.envs.isEmpty
                              ? const Text('暂无环境变量')
                              : Column(
                                  children: detail.envs
                                      .map((env) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${env['key'] ?? '--'}：', style: const TextStyle(fontWeight: FontWeight.w700)),
                                                Expanded(child: Text((env['value'] ?? '--').toString())),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                FutureBuilder<List<String>>(
                  future: _logDatesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _DetailErrorState(onRetry: _refresh);
                    }
                    final dates = snapshot.data ?? const [];
                    if (dates.isEmpty) {
                      return const Center(child: Text('暂无日志日期')); 
                    }
                    final currentDate = _selectedDate ?? dates.first;
                    if (_selectedDate == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedDate == null) {
                          _selectDate(dates.first);
                        }
                      });
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: DropdownButtonFormField<String>(
                            initialValue: currentDate,
                            decoration: const InputDecoration(labelText: '日志日期', border: OutlineInputBorder()),
                            items: dates.map((date) => DropdownMenuItem(value: date, child: Text(date))).toList(),
                            onChanged: (value) {
                              if (value != null) _selectDate(value);
                            },
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<String>>(
                            future: _logsFuture,
                            builder: (context, logSnapshot) {
                              if (logSnapshot.connectionState != ConnectionState.done) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (logSnapshot.hasError) {
                                return _DetailErrorState(onRetry: _refresh);
                              }
                              final logs = logSnapshot.data ?? const [];
                              if (logs.isEmpty) return const Center(child: Text('暂无日志内容'));
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemBuilder: (context, index) => SelectableText(logs[index]),
                                separatorBuilder: (_, __) => const Divider(height: 20),
                                itemCount: logs.length,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({required this.left, required this.right, required this.extra});

  final String left;
  final String right;
  final String extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(left)),
          Expanded(child: Text(right, textAlign: TextAlign.center)),
          Expanded(child: Text(extra, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.tonal(onPressed: onRetry, child: const Text('加载失败，点我重试')),
    );
  }
}
