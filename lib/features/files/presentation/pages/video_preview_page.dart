import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({
    super.key,
    required this.baseUrl,
    required this.path,
    required this.name,
    required this.sid,
    this.cookieHeader,
    this.synoToken,
  });

  final String baseUrl;
  final String path;
  final String name;
  final String? sid;
  final String? cookieHeader;
  final String? synoToken;

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
    // 与 dsm_helper 完全一致，_sid 在 URL 中也保留
    final encodedName = Uri.encodeComponent(widget.name);
    final encodedDlink = '%22${_utf8Encode(widget.path)}%22';
    final sid = widget.sid ?? '';
    return '${widget.baseUrl}/fbdownload/$encodedName?dlink=$encodedDlink&_sid=%22$sid%22&mode=open';
  }

  /// 构建 HTTP Headers（同时在 URL 和 Header 中传递认证信息）
  Map<String, String> get _httpHeaders {
    final headers = <String, String>{};
    if (widget.cookieHeader != null && widget.cookieHeader!.isNotEmpty) {
      headers['Cookie'] = widget.cookieHeader!;
    }
    if (widget.synoToken != null && widget.synoToken!.isNotEmpty) {
      headers['X-SYNO-TOKEN'] = widget.synoToken!;
    }
    debugPrint('[VideoPreview] headers: $headers');
    return headers;
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
    debugPrint('[VideoPreview] streamUrl: $_streamUrl');
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      backgroundColor: Colors.black,
      body: OmniVideoPlayer(
        configuration: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.network(
            videoUrl: Uri.parse(_streamUrl),
            httpHeaders: _httpHeaders,
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
