import 'dart:convert';

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

  /// UTF-8 编码后转十六进制字符串（与 NAS videoplayer.js bin2hex 完全一致）
  String _bin2hex(String data) {
    final utf8Bytes = utf8.encode(data); // 先 UTF-8 编码
    return utf8Bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(); // 再转十六进制
  }

  String get _streamUrl {
    // 参考 NAS 网页抓包格式：
    // /fbdownload/{filename}?mode=download&dlink={utf8Path}&SynoToken={token}
    final encodedName = Uri.encodeComponent(widget.name);
    final encodedDlink = _bin2hex(widget.path);
    final synoToken = widget.synoToken ?? '';
    // mode=download, stdhtml=false
    final url = '${widget.baseUrl}/fbdownload/$encodedName?mode=download&stdhtml=false&dlink=%22$encodedDlink%22&SynoToken=$synoToken';
    debugPrint('[VideoPreview] path: ${widget.path}');
    debugPrint('[VideoPreview] dlink hex: $encodedDlink');
    debugPrint('[VideoPreview] streamUrl: $url');
    return url;
  }

  /// 构建 HTTP Headers（参考 NAS 网页抓包）
  Map<String, String> get _httpHeaders {
    final headers = <String, String>{
      'accept': '*/*',
      'accept-language': 'zh-CN,zh;q=0.9',
      'cache-control': 'no-cache',
      'pragma': 'no-cache',
      // 注意：不要加 range header！加了会导致 DSM 返回 206 而不返回 Content-Length，
      // 播放器获取不到总时长，手势Seek会失效（_onDoubleTap 里 newPosition > duration 会 return）
      // referer 包含 launchApp 参数，NAS 需要这个来识别为视频播放器
      'referer': '${widget.baseUrl}/?launchApp=SYNO.SDS.VideoPlayer2.Application&SynoToken=${widget.synoToken ?? ''}',
      'user-agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
    };
    if (widget.cookieHeader != null && widget.cookieHeader!.isNotEmpty) {
      headers['Cookie'] = widget.cookieHeader!;
    }
    debugPrint('[VideoPreview] streamUrl: $_streamUrl');
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      backgroundColor: Colors.black,
      body: OmniVideoPlayer(
        configuration: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.network(
            videoUrl: Uri.parse(_streamUrl),
            httpHeaders: _httpHeaders,
          ),
          playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
            showPlaybackSpeedButton: true,
            showFullScreenButton: true,
            showMuteUnMuteButton: true,
            enableForwardGesture: true,
            enableBackwardGesture: true,
            enableExitFullscreenOnVerticalSwipe: true,
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
