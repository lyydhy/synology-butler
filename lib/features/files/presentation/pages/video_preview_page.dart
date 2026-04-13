import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({
    super.key,
    required this.baseUrl,
    required this.path,
    required this.name,
    required this.synoToken,
  });

  final String baseUrl;
  final String path;
  final String name;
  final String? synoToken;

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

  String get _streamUrl {
    // 使用 FileStation Download API 直接获取视频文件
    // DSM 的 /webapi/entry.cgi?api=SYNO.FileStation.Download
    final encodedPath = Uri.encodeComponent(jsonEncode([widget.path]));
    final sid = widget.synoToken ?? '';
    return '${widget.baseUrl}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&mode=download&path=$encodedPath&_sid=$sid';
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
