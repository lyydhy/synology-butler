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

  Future<void> _init() async {
    try {
      final token = widget.synoToken;
      if (token == null || token.isEmpty) {
        throw Exception('缺少 SynoToken，无法远程播放');
      }

      final launchParam = 'ieMode=9&is_drive=false&path=${Uri.encodeComponent(widget.path)}&file_id=${Uri.encodeComponent(widget.path)}';
      final uri = Uri.parse(widget.baseUrl).replace(
        path: '/',
        queryParameters: {
          'launchApp': 'SYNO.SDS.VideoPlayer2.Application',
          'SynoToken': token,
          'launchParam': launchParam,
          'ieMode': '9',
        },
      );

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
