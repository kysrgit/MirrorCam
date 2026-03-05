import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/utils/logger.dart';

/// Remote video stream'i alan ve RTCVideoRenderer'a bağlayan servis.
/// Receiver ekranında tam ekran video gösterimi için kullanılır.
class StreamReceiver {
  RTCVideoRenderer? _renderer;

  /// Başlatılmış renderer
  RTCVideoRenderer? get renderer => _renderer;

  /// Remote stream referansı
  MediaStream? _remoteStream;
  MediaStream? get remoteStream => _remoteStream;

  /// Renderer'ı oluşturur ve başlatır
  Future<RTCVideoRenderer> initialize() async {
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();
    Logger.info('RTCVideoRenderer başlatıldı');
    return _renderer!;
  }

  /// Remote stream'i renderer'a bağlar (onTrack event'inden gelir)
  void setRemoteStream(MediaStream stream) {
    _remoteStream = stream;
    if (_renderer != null) {
      _renderer!.srcObject = stream;
      Logger.info('Remote stream renderer\'a bağlandı');
    } else {
      Logger.warning('Renderer henüz başlatılmadı, stream bekletiliyor');
    }
  }

  /// Tüm kaynakları temizler
  Future<void> dispose() async {
    _renderer?.srcObject = null;
    await _renderer?.dispose();
    _renderer = null;
    _remoteStream = null;
    Logger.info('StreamReceiver kaynakları temizlendi');
  }
}
