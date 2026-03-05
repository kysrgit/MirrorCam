import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC akışını tam ekran gösteren widget
class FullscreenVideo extends StatelessWidget {
  /// Video oynatıcı (renderer)
  final RTCVideoRenderer renderer;

  /// Sabit yapıcı
  const FullscreenVideo({super.key, required this.renderer});

  @override
  Widget build(BuildContext context) {
    return RTCVideoView(
      renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
