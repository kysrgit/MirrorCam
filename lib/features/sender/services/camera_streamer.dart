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
      _isTorchOn = false;
    } catch (e, st) {
      Logger.error('Kamera durdurulurken hata', e, st);
    }
  }

  bool _isTorchOn = false;

  /// Fener açık mı kapalı mı
  bool get isTorchOn => _isTorchOn;

  /// Cihazda fener var mı kontrol et
  Future<bool> get isTorchAvailable async {
    final videoTracks = _localStream?.getVideoTracks();
    if (videoTracks == null || videoTracks.isEmpty) return false;
    final videoTrack = videoTracks.first;

    try {
      return await videoTrack.hasTorch();
    } catch (_) {
      return false;
    }
  }

  /// Fener (torch/flashlight) aç/kapat
  /// Video akışını ETKİLEMEZ — sadece LED'i kontrol eder
  Future<bool> toggleTorch() async {
    if (_localStream == null) return false;

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return false;
    final videoTrack = videoTracks.first;

    try {
      final currentState = await videoTrack.hasTorch();
      if (!currentState) {
        Logger.warning('Bu cihazda fener desteklenmiyor');
        return false;
      }

      _isTorchOn = !_isTorchOn;
      await videoTrack.setTorch(_isTorchOn);
      Logger.info('Fener: ${_isTorchOn ? "AÇIK" : "KAPALI"}');
      return _isTorchOn;
    } catch (e) {
      Logger.warning('Fener kontrol hatası: $e');
      return false;
    }
  }
}
