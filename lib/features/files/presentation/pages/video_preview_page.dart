import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

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
  OmniPlaybackController? _controller;

  /// UTF-8 十六进制编码（与 dsm_helper Util.utf8Encode 保持一致）
  String _utf8Encode(String data) {
    return data.codeUnits.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String get _streamUrl {
    // 与 dsm_helper 完全一致
    final encodedName = Uri.encodeComponent(widget.name);
    final encodedDlink = '%22${_utf8Encode(widget.path)}%22';
    final sid = widget.sid ?? '';
    return '${widget.baseUrl}/fbdownload/$encodedName?dlink=$encodedDlink&_sid=%22$sid%22&mode=open';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      backgroundColor: Colors.black,
      body: OmniVideoPlayer(
        configuration: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.network(
            videoUrl: Uri.parse(_streamUrl),
            httpHeaders: const {},  // DSM 的认证通过 URL 中的 _sid 参数完成
          ),
        ),
        callbacks: VideoPlayerCallbacks(
          onControllerCreated: (controller) {
            _controller = controller..addListener(_onUpdate);
          },
        ),
      ),
    );
  }
}
