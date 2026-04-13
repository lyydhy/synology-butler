import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({
    super.key,
    required this.baseUrl,
    required this.path,
    required this.name,
    required this.sid,
  });

  final String baseUrl;
  final String path;
  final String name;
  final String? sid;

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// UTF-8 十六进制编码（与 dsm_helper Util.utf8Encode 保持一致）
  String _utf8Encode(String data) {
    final utf8Bytes = utf8.encode(data);
    return utf8Bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String get _streamUrl {
    // 使用 DSM 的 /fbdownload/ 端点（与 dsm_helper 完全一致）
    // dsm_helper: /fbdownload/${file['name']}?dlink=%22${Util.utf8Encode(file['path'])}%22&_sid=%22${Util.sid}%22&mode=open
    final encodedDlink = '%22${_utf8Encode(widget.path)}%22';
    final sid = widget.sid ?? '';
    // 注意：dsm_helper 中 filename 没有用 Uri.encodeComponent
    final url = '${widget.baseUrl}/fbdownload/${widget.name}?dlink=$encodedDlink&_sid=%22$sid%22&mode=open';
    debugPrint('[VideoPreview] baseUrl: ${widget.baseUrl}');
    debugPrint('[VideoPreview] path: ${widget.path}');
    debugPrint('[VideoPreview] name: ${widget.name}');
    debugPrint('[VideoPreview] sid: $sid');
    debugPrint('[VideoPreview] streamUrl: $url');
    return url;
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(_streamUrl);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      controller.play();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      backgroundColor: Colors.black,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  )
                : _controller == null
                    ? const Text('视频加载失败', style: TextStyle(color: Colors.white))
                    : AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio == 0 ? 16 / 9 : _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
      ),
      floatingActionButton: _controller == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                final controller = _controller!;
                setState(() {
                  controller.value.isPlaying ? controller.pause() : controller.play();
                });
              },
              child: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
    );
  }
}
