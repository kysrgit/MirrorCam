import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/network_utils.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/services/sound_service.dart';
import '../../../../shared/services/webrtc_service.dart';
import 'package:flutter/foundation.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/camera_streamer.dart';
import '../services/signaling_server.dart';

part 'sender_provider.g.dart';

enum ConnectionStatus {
  initializing,
  waiting, // Bekleniyor
  connected, // Bağlandı
  error, // Hata
  disconnected,
}

class SenderState {
  final ConnectionStatus status;
  final String? localIp;
  final int port;
  final RTCVideoRenderer? localRenderer;
  final int latencyMs;
  final String? errorMessage;
  final bool isTorchOn;
  final bool isTorchAvailable;

  const SenderState({
    this.status = ConnectionStatus.initializing,
    this.localIp,
    this.port = 8765,
    this.localRenderer,
    this.latencyMs = 0,
    this.errorMessage,
    this.isTorchOn = false,
    this.isTorchAvailable = false,
  });

  SenderState copyWith({
    ConnectionStatus? status,
    String? localIp,
    int? port,
    RTCVideoRenderer? localRenderer,
    int? latencyMs,
    String? errorMessage,
    bool? isTorchOn,
    bool? isTorchAvailable,
  }) {
    return SenderState(
      status: status ?? this.status,
      localIp: localIp ?? this.localIp,
      port: port ?? this.port,
      localRenderer: localRenderer ?? this.localRenderer,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      isTorchAvailable: isTorchAvailable ?? this.isTorchAvailable,
    );
  }
}

@riverpod
class SenderNotifier extends _$SenderNotifier {
  late CameraStreamer _cameraStreamer;
  late final SignalingServer _signalingServer;
  late final WebRTCService _webrtcService;

  @visibleForTesting
  set cameraStreamer(CameraStreamer streamer) => _cameraStreamer = streamer;
  Timer? _latencyTimer;

  // Latency Smoothing (EMA) iÃ§in state
  double _ema = 0;
  bool _emaInitialized = false;
  static const double _alpha = 0.3; // %30 yeni deÄer, %70 geÃ§miÅ
  final Map<int, int> _pendingPings = {};
  int _pingIdCounter = 0;

  @override
  SenderState build() {
    _cameraStreamer = CameraStreamer();
    _signalingServer = SignalingServer();
    _webrtcService = WebRTCService();

    // Dispose resources on provider destroy
    ref.onDispose(() {
      unawaited(_cleanup());
    });

    _initSender();
    return const SenderState();
  }

  Future<void> toggleTorch() async {
    final result = await _cameraStreamer.toggleTorch();
    state = state.copyWith(isTorchOn: result);
  }

  Future<void> _initSender() async {
    try {
      // WiFi High Perf kilidini al (Gecikmeyi düşürür)
      await NetworkUtils.enableWifiHighPerformance();

      // 0. İzinleri kontrol et
      final permStatus = await PermissionUtils.requestCameraPermission();
      if (permStatus == PermissionResult.denied) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'Kamera izni verilmedi. Yayın yapılamaz.',
        );
        return;
      } else if (permStatus == PermissionResult.permanentlyDenied) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage:
              'Kamera izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        );
        return;
      }

      // 1. IP Adresini bul
      final ip = await NetworkUtils.getLocalIpAddress();
      if (ip == null) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage:
              'Yerel IP adresi bulunamadı. Lütfen Wi-Fi\'ye bağlı olduğunuzdan emin olun.',
        );
        return;
      }

      state = state.copyWith(status: ConnectionStatus.waiting, localIp: ip);

      // 2. Ayarları al ve kamerayı başlat
      final settings = ref.read(settingsNotifierProvider);
      final profile = settings.qualityProfile;

      final renderer = RTCVideoRenderer();
      await renderer.initialize();

      final stream = await _cameraStreamer.startCamera(profile: profile);
      if (stream != null) {
        renderer.srcObject = stream;
        state = state.copyWith(localRenderer: renderer);
      } else {
        throw Exception('Kamera başlatılamadı');
      }

      // 3. Signaling (WebSocket) sunucusunu başlat
      await _signalingServer.start(port: state.port);

      // İstemci bağlantı durumunu dinle
      _signalingServer.onClientConnected.listen((isConnected) async {
        if (isConnected) {
          await _onClientConnected();
        } else {
          // İstemci koptu
          state = state.copyWith(status: ConnectionStatus.waiting);
          await _resetWebRTC();
        }
      });

      // Gelen WebRTC sinyallerini dinle
      _signalingServer.messages.listen((message) {
        _handleSignalingMessage(message);
      });

      final torchAvailable = await _cameraStreamer.isTorchAvailable;
      state = state.copyWith(
        isTorchAvailable: torchAvailable,
        isTorchOn: false,
      );
    } catch (e, st) {
      Logger.error('Sender başlatılırken hata oluştu', e, st);
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Başlatma hatası: $e',
      );
      await SoundService.playDisconnected();
    }
  }

  Future<void> _onClientConnected() async {
    state = state.copyWith(status: ConnectionStatus.connected);
    await SoundService.playConnected();

    // Ping/Pong + Remote Command için dinleme
    _webrtcService.onDataChannelMessage = (message) {
      if (message.startsWith('pong:')) {
        final parts = message.split(':');
        if (parts.length == 3) {
          final pingId = int.tryParse(parts[1]);
          final originalTs = int.tryParse(parts[2]);

          if (pingId != null &&
              originalTs != null &&
              _pendingPings.containsKey(pingId)) {
            _pendingPings.remove(pingId);
            final now = DateTime.now().millisecondsSinceEpoch;
            final rtt = now - originalTs;
            final oneWayLatency = rtt ~/ 2;

            // EMA Smoothing
            if (!_emaInitialized) {
              _ema = oneWayLatency.toDouble();
              _emaInitialized = true;
            } else {
              _ema = _alpha * oneWayLatency + (1 - _alpha) * _ema;
            }

            // state'i güncelle
            state = state.copyWith(latencyMs: _ema.round());
          }
        }
      } else if (message.startsWith('cmd:')) {
        _handleRemoteCommand(message);
      }
    };

    // DataChannel açıldığında fener durumunu bildir
    _webrtcService.onDataChannelOpen = () {
      Logger.info('DataChannel açıldı, fener durumu gönderiliyor...');
      unawaited(_sendInitialTorchStatus());
    };

    // WebRTC bağlantısını kur ve SDP Offer oluştur
    final pc = await _webrtcService.createConnection();
    if (pc == null || _cameraStreamer.stream == null) return;

    // ICE Candidate'ları karşıya gönder
    pc.onIceCandidate = (candidate) {
      _signalingServer.sendMessage({
        'type': 'candidate',
        'data': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    // Ayarlardan profile al
    final settings = ref.read(settingsNotifierProvider);
    final profile = settings.qualityProfile;
    final targetBitrateKbps = profile.maxBitrate ~/ 1000;

    // Offer olustur
    final offer = await _webrtcService.createOffer(
      _cameraStreamer.stream!,
      startBitrate: targetBitrateKbps ~/ 2,
      maxBitrate: targetBitrateKbps,
    );

    // Profile'a gÃ¶re stream constraintlerini uygula
    await _webrtcService.applyStreamConstraints(profile);

    if (offer != null) {
      // Offer'ı sinyal sunucusu üzerinden Receiver'a gönder
      _signalingServer.sendMessage({
        'type': 'offer',
        'data': {'sdp': offer.sdp, 'type': offer.type},
      });

      // Latency ölçümü başlat
      _startLatencyMeasurement();
    }
  }

  void _startLatencyMeasurement() {
    _latencyTimer?.cancel();
    _pendingPings.clear();

    // 2 sn yerine 1 sn'de bir Ã¶lÃ§Ã¼m yap
    _latencyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pingId = _pingIdCounter++;

      _pendingPings[pingId] = timestamp;

      // Temizlik: 5 saniyeden eski yanÄ±tsÄ±z pingleri temizle
      _pendingPings.removeWhere((id, ts) => timestamp - ts > 5000);

      _webrtcService.sendDataChannelMessage('ping:$pingId:$timestamp');
    });
  }

  // ─── Fener Remote Control ───────────────────────────────────────

  /// Receiver'dan gelen remote komutları işler
  void _handleRemoteCommand(String data) {
    final parts = data.split(':');
    // parts[0] = "cmd", parts[1] = hedef, parts[2] = aksiyon
    if (parts.length >= 3 && parts[1] == 'torch') {
      switch (parts[2]) {
        case 'toggle':
          _handleTorchToggle();
        case 'on':
          _handleTorchOn();
        case 'off':
          _handleTorchOff();
      }
    }
  }

  /// Fener toggle komutu (Receiver'dan gelen)
  Future<void> _handleTorchToggle() async {
    try {
      final result = await _cameraStreamer.toggleTorch();
      state = state.copyWith(isTorchOn: result);
      _sendStatus('torch', result ? 'on' : 'off');
    } catch (e) {
      Logger.warning('Torch toggle hatası: $e');
      _sendStatus('torch', 'error');
    }
  }

  /// Feneri aç komutu
  Future<void> _handleTorchOn() async {
    try {
      if (!_cameraStreamer.isTorchOn) {
        final result = await _cameraStreamer.toggleTorch();
        state = state.copyWith(isTorchOn: result);
      }
      _sendStatus('torch', 'on');
    } catch (e) {
      Logger.warning('Torch on hatası: $e');
      _sendStatus('torch', 'error');
    }
  }

  /// Feneri kapat komutu
  Future<void> _handleTorchOff() async {
    try {
      if (_cameraStreamer.isTorchOn) {
        final result = await _cameraStreamer.toggleTorch();
        state = state.copyWith(isTorchOn: result);
      }
      _sendStatus('torch', 'off');
    } catch (e) {
      Logger.warning('Torch off hatası: $e');
      _sendStatus('torch', 'error');
    }
  }

  /// Status mesajı gönderir (DataChannel üzerinden Receiver'a)
  void _sendStatus(String target, String value) {
    _webrtcService.sendDataChannelMessage('status:$target:$value');
  }

  /// Bağlantı kurulduğunda Receiver'a fener durumunu bildirir
  Future<void> _sendInitialTorchStatus() async {
    final available = await _cameraStreamer.isTorchAvailable;
    if (!available) {
      _sendStatus('torch', 'unavailable');
    } else {
      _sendStatus('torch', _cameraStreamer.isTorchOn ? 'on' : 'off');
    }
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (type == null || data == null) return;

    switch (type) {
      case 'answer':
        final sdp = data['sdp'] as String;
        final answerType = data['type'] as String;
        await _webrtcService.setRemoteDescription(
          RTCSessionDescription(sdp, answerType),
        );
        break;
      case 'candidate':
        final candidateStr = data['candidate'] as String;
        final sdpMid = data['sdpMid'] as String;
        final sdpMLineIndex = data['sdpMLineIndex'] as int;

        await _webrtcService.addIceCandidate(
          RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex),
        );
        break;
      case 'bye':
        await _resetWebRTC();
        state = state.copyWith(status: ConnectionStatus.waiting);
        await SoundService.playDisconnected();
        break;
    }
  }

  Future<void> _resetWebRTC() async {
    _latencyTimer?.cancel();
    await _webrtcService.dispose();
  }

  Future<void> disconnect() async {
    _signalingServer.sendMessage({'type': 'bye', 'data': <String, dynamic>{}});
    await _resetWebRTC();
    state = state.copyWith(status: ConnectionStatus.waiting, isTorchOn: false);
    await SoundService.playDisconnected();
  }

  Future<void> _cleanup() async {
    _latencyTimer?.cancel();
    await _cameraStreamer.stopCamera();
    await _signalingServer.stop();
    await _webrtcService.dispose();
    await state.localRenderer?.dispose();

    // WiFi kilidini bÄ±rak
    await NetworkUtils.disableWifiHighPerformance();
  }
}
