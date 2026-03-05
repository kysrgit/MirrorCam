import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/quality_profile.dart';

/// Göndericinin cihazından kamera akışını yöneten servis.
/// Bu servis; sadece arka kamerayı (facingMode: environment),
/// ses olmadan (audio: false) başlatır.
class CameraStreamer {
  MediaStream? _localStream;

  /// Başlatılmış olan lokal akış
  MediaStream? get stream => _localStream;

  /// Kamerayı belirtilen profil ile başlatır.
  Future<MediaStream?> startCamera({QualityProfile? profile}) async {
    final conf = profile ?? QualityProfile.ultra;
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'facingMode': 'environment',
          'mandatory': {
            'minWidth': conf.width.toString(),
            'minHeight': conf.height.toString(),
            'minFrameRate': conf.fps.toString(),
            'maxFrameRate': conf.fps.toString(), // Sabit FPS zorla
          },
          'optional': <dynamic>[],
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      Logger.info('Arka kamera başarıyla başlatıldı: 1080p@30fps');
      return _localStream;
    } catch (e, st) {
      Logger.error('Kamera başlatılamadı', e, st);
      return null;
    }
  }

  /// Kamerayı durdurur ve kaynakları serbest bırakır.
  Future<void> stopCamera() async {
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
        Logger.info('Kamera durduruldu');
      }
    } catch (e, st) {
      Logger.error('Kamera durdurulurken hata', e, st);
    }
  }
}
