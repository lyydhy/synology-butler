import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/file_size_formatter.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../providers/package_providers.dart';

/// 套件详情页。
///
/// 详情页与列表页共享安装任务状态，因此只监听精简后的安装状态 provider。
class PackageDetailPage extends ConsumerWidget {
  const PackageDetailPage({super.key, required this.item});

  final PackageItem item;

  /// 选择套件安装所在的存储卷。
  Future<String?> _pickVolume(BuildContext context, WidgetRef ref) async {
    final volumes = await ref.read(packageVolumesProvider.future);
    if (volumes.isEmpty || !context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('选择安装位置'),
                subtitle: Text('请选择套件安装的存储卷'),
              ),
              for (final volume in volumes) _DetailVolumeTile(volume: volume),
            ],
          ),
        );
      },
    );
  }

  /// 安装前提示可能被暂停的套件。
  Future<bool> _confirmQueueImpact(BuildContext context, WidgetRef ref) async {
    final impact = ref.read(packageInstallStateProvider).pendingQueueImpact;
    if (impact == null || impact.pausedPackages.isEmpty) {
      return true;
    }

    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('确认更新影响'),
            content: Text(
              '继续安装/更新 ${item.displayName} 时，以下套件可能会被暂停：\n\n${impact.pausedPackages.join('、')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('继续'),
              ),
            ],
          ),
        )) ??
        false;
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installState = ref.watch(packageInstallStateProvider);
    final installStatus = installState.statusText;
    final isInstallingThis = installState.isInstalling(item.id);

    return Scaffold(
      appBar: AppBar(title: Text(item.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头部信息卡片
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.apps_rounded, size: 36, color: Colors.grey),
                              )
                            : const Icon(Icons.apps_rounded, size: 36, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _DetailChip(
                                  text: item.canUpdate ? '可更新' : item.isInstalled ? '已安装' : '未安装',
                                  color: item.canUpdate
                                      ? Colors.orange
                                      : item.isInstalled
                                          ? Colors.blue
                                          : Colors.grey,
                                ),
                                if (item.isRunning) const _DetailChip(text: '运行中', color: Colors.green),
                                if (item.isBeta) const _DetailChip(text: 'Beta', color: Colors.deepPurple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(item.description.isEmpty ? '暂无描述' : item.description),
                  const SizedBox(height: 20),
                  _InfoRow(label: '商店版本', value: item.version),
                  if (item.installedVersion != null && item.installedVersion!.isNotEmpty)
                    _InfoRow(label: '已安装版本', value: item.installedVersion!),
                  if (item.status != null && item.status!.isNotEmpty)
                    _InfoRow(label: '状态', value: item.status!),
                  if (item.distributor != null && item.distributor!.isNotEmpty)
                    _InfoRow(label: '发行方', value: item.distributor!, url: item.distributorUrl),
                  if (item.maintainer != null && item.maintainer!.isNotEmpty)
                    _InfoRow(label: '维护者', value: item.maintainer!, url: item.maintainerUrl),
                  if (item.installPath != null && item.installPath!.isNotEmpty)
                    _InfoRow(label: '安装路径', value: item.installPath!),
                  if (item.downloadCount != null && item.downloadCount! > 0)
                    _InfoRow(label: '下载次数', value: _formatCount(item.downloadCount!)),
                ],
              ),
            ),
          ),

          // 截图轮播
          if (item.screenshots.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '截图',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _ScreenshotSwiper(screenshots: item.screenshots),
          ],

          // 更新日志
          if (item.changelog != null && item.changelog!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '更新日志',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Html(
                  data: item.changelog!,
                  style: {
                    'body': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                    'p': Style(fontSize: FontSize(14)),
                  },
                ),
              ),
            ),
          ],

          // 安装进度提示
          if (installStatus != null && installStatus.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('当前任务：$installStatus')),
                  ],
                ),
              ),
            ),
          ],

          // 操作按钮
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (item.isInstalled && !item.isRunning)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(packageStartProvider)(item);
                    if (context.mounted) {
                      Toast.success('已发送启动请求：${item.displayName}');
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('启动'),
                ),
              if (item.isInstalled && item.isRunning)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(packageStopProvider)(item);
                    if (context.mounted) {
                      Toast.success('已发送停止请求：${item.displayName}');
                    }
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('停止'),
                ),
              if (item.isInstalled)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('确认卸载'),
                            content: Text('确定要卸载 ${item.displayName} 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: const Text('卸载'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!confirmed) return;

                    await ref.read(packageUninstallProvider)(item);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('卸载'),
                ),
              FilledButton.icon(
                onPressed: (item.isInstalled && !item.canUpdate) || isInstallingThis
                    ? null
                    : () async {
                        final volumePath = await _pickVolume(context, ref);
                        if (volumePath == null || volumePath.isEmpty) return;

                        await ref.read(packagePrepareInstallProvider)(item);
                        if (!context.mounted) return;

                        final confirmed = await _confirmQueueImpact(context, ref);
                        if (!confirmed) return;

                        try {
                          await ref.read(packageInstallProvider)(item, volumePath);
                          if (context.mounted) {
                            Toast.success('${item.displayName} 安装/更新任务已完成或已提交');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Toast.error('套件安装失败：$e');
                          }
                        }
                      },
                icon: const Icon(Icons.system_update_alt_rounded),
                label: Text(
                  isInstallingThis
                      ? '进行中'
                      : item.canUpdate
                          ? '更新'
                          : item.isInstalled
                              ? '已安装'
                              : '安装',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 截图轮播组件，使用 PageView 实现
class _ScreenshotSwiper extends StatefulWidget {
  const _ScreenshotSwiper({required this.screenshots});

  final List<String> screenshots;

  @override
  State<_ScreenshotSwiper> createState() => _ScreenshotSwiperState();
}

class _ScreenshotSwiperState extends State<_ScreenshotSwiper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.screenshots.length,
            itemBuilder: (context, index) {
              final screenshot = widget.screenshots[index];
              final isHttp = screenshot.startsWith('http');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: GestureDetector(
                      onTap: () => _openFullScreen(context, screenshot),
                      child: isHttp
                          ? CachedNetworkImage(
                              imageUrl: screenshot,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _FallbackContent(url: screenshot),
                            )
                          : _FallbackContent(url: screenshot),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.screenshots.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.screenshots.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  void _openFullScreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _FallbackContent(url: url),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              url,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态标签
class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 信息行组件，支持链接
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.url});

  final String label;
  final String value;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final isLink = url != null && url!.isNotEmpty;
    final content = Text(
      value,
      style: TextStyle(
        color: isLink ? Theme.of(context).colorScheme.primary : null,
        decoration: isLink ? TextDecoration.underline : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: () => launchUrl(Uri.parse(url!)),
                    child: content,
                  )
                : content,
          ),
        ],
      ),
    );
  }
}

/// 存储卷选择 Tile
class _DetailVolumeTile extends StatelessWidget {
  const _DetailVolumeTile({required this.volume});

  final PackageVolume volume;

  @override
  Widget build(BuildContext context) {
    final freeText = volume.freeBytes != null && volume.freeBytes!.isNotEmpty
        ? FileSizeFormatter.format(int.tryParse(volume.freeBytes!) ?? 0)
        : null;

    return ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: Text(volume.displayName.isEmpty ? volume.path : volume.displayName),
      subtitle: Text(
        [
          if (volume.description.isNotEmpty) volume.description,
          if (volume.fsType.isNotEmpty) volume.fsType,
          if (freeText != null) '可用 $freeText',
        ].join(' · '),
      ),
      onTap: () => Navigator.of(context).pop(volume.path),
    );
  }
}
