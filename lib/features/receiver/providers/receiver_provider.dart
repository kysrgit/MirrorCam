import 'dart:async';
import 'dart:collection';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/network_utils.dart';
import '../../../shared/services/sound_service.dart';
import '../../../shared/services/webrtc_service.dart';
import '../services/signaling_client.dart';
import '../services/stream_receiver.dart';

part 'receiver_provider.g.dart';

/// Receiver bağlantı durumu
enum ReceiverConnectionStatus {
  idle, // Başlangıç: QR tarayıcı gösterilir
  connecting, // WebSocket / WebRTC bağlantısı kuruluyor
  connected, // Video akışı alınıyor
  reconnecting, // Bağlantı koptu, yeniden deneniyor
  failed, // Tüm denemeler başarısız
  error, // Genel hata
}

/// Receiver modülünün tüm durumunu tutan sınıf
class ReceiverState {
  final ReceiverConnectionStatus status;
  final bool isMirrored;
  final double zoomLevel;
  final RTCVideoRenderer? remoteRenderer;
  final int latencyMs;
  final String? errorMessage;

  /// Fener (torch) durumu — Sender'dan gelen status mesajlarıyla güncellenir
  final bool isTorchOn;
  final bool isTorchAvailable;
  final bool isTorchLoading;

  const ReceiverState({
    this.status = ReceiverConnectionStatus.idle,
    this.isMirrored = false,
    this.zoomLevel = 1.0,
    this.remoteRenderer,
    this.latencyMs = 0,
    this.errorMessage,
    this.isTorchOn = false,
    this.isTorchAvailable = false,
    this.isTorchLoading = false,
  });

  ReceiverState copyWith({
    ReceiverConnectionStatus? status,
    bool? isMirrored,
    double? zoomLevel,
    RTCVideoRenderer? remoteRenderer,
    int? latencyMs,
    String? errorMessage,
    bool? isTorchOn,
    bool? isTorchAvailable,
    bool? isTorchLoading,
  }) {
    return ReceiverState(
      status: status ?? this.status,
      isMirrored: isMirrored ?? this.isMirrored,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      isTorchAvailable: isTorchAvailable ?? this.isTorchAvailable,
      isTorchLoading: isTorchLoading ?? this.isTorchLoading,
    );
  }
}

@riverpod
class ReceiverNotifier extends _$ReceiverNotifier {
  late final SignalingClient _signalingClient;
  late final WebRTCService _webrtcService;
  late final StreamReceiver _streamReceiver;

  /// ICE candidate buffer — PeerConnection hazır olmadan gelen candidate'ları
  /// burada biriktirip, remote description ayarlandıktan sonra ekliyoruz.
  final List<RTCIceCandidate> _pendingCandidates = [];

  /// Remote description ayarlandı mı? (Candidate'ları ekleyebilir miyiz?)
  bool _remoteDescriptionSet = false;

  /// Mesaj kuyruğu — mesajları sırayla işlemek için (race condition önleme)
  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  bool _processingMessage = false;

  StreamSubscription<dynamic>? _messageSubscription;
  StreamSubscription<dynamic>? _connectionSubscription;

  @override
  ReceiverState build() {
    _signalingClient = SignalingClient();
    _webrtcService = WebRTCService();
    _streamReceiver = StreamReceiver();

    ref.onDispose(() {
      unawaited(_cleanup());
    });

    return const ReceiverState();
  }

  /// QR koddan veya manuel girişten gelen IP:PORT ile bağlantı başlatır
  Future<void> connectTo(String ip, int port, [String token = '']) async {
    try {
      state = state.copyWith(status: ReceiverConnectionStatus.connecting);
      // ignore: avoid_print
      print('[DEBUG-RP] connectTo called: $ip:$port');

      // Önceki bağlantı state'ini sıfırla
      _pendingCandidates.clear();
      _remoteDescriptionSet = false;
      _messageQueue.clear();
      _processingMessage = false;

      // WiFi High Pef kilidini kapat
      await NetworkUtils.disableWifiHighPerformance();

      // 1. Renderer'ı başlat
      final renderer = await _streamReceiver.initialize();
      state = state.copyWith(remoteRenderer: renderer);

      // WiFi High Pef kilidini al
      await NetworkUtils.enableWifiHighPerformance();

      // Sinyal event'lerini dinle
      _setupSignalingListeners();

      // Sinyal sunucusuna WebSocket uzerinden baglan
      await _signalingClient.connect(ip, port, token);

      // WebRTC servisini baslat
      await _webrtcService.createConnectionForReceiver();

      // Timeout: 15 saniyede receiver connected olmazsa error bas.
      Timer(const Duration(seconds: 15), () {
        if (state.status == ReceiverConnectionStatus.connecting ||
            state.status == ReceiverConnectionStatus.reconnecting) {
          state = state.copyWith(
            status: ReceiverConnectionStatus.error,
            errorMessage: 'WebRTC bağlantı zaman aşımı. Sunucu yanıtlamadı.',
          );
          _signalingClient.disconnect();
        }
      });
    } catch (e, st) {
      Logger.error('Receiver bağlantısı başlatılırken hata', e, st);
      state = state.copyWith(
        status: ReceiverConnectionStatus.error,
        errorMessage: 'Bağlantı hatası: $e',
      );
      await SoundService.playDisconnected();
    }
  }

  /// Sinyal mesajlarını ve bağlantı durumunu dinlemeye başlar
  void _setupSignalingListeners() {
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();

    _connectionSubscription = _signalingClient.onConnectionState.listen((
      isConnected,
    ) {
      if (!isConnected && state.status == ReceiverConnectionStatus.connected) {
        state = state.copyWith(status: ReceiverConnectionStatus.reconnecting);
      }
    });

    _messageSubscription = _signalingClient.messages.listen(
      _handleSignalingMessage,
      onError: (dynamic error) {
        _handleSignalingDisconnect();
      },
    );
  }

  /// Gelen sinyal mesajlarını kuyruğa ekle ve sırayla işle
  void _handleSignalingMessage(Map<String, dynamic> message) {
    _enqueueMessage(message);
  }

  /// WebSocket bağlantısı koptuğunda çağrılır
  void _handleSignalingDisconnect() {
    if (state.status == ReceiverConnectionStatus.connected) {
      // Bağlantı koptu
      state = state.copyWith(status: ReceiverConnectionStatus.reconnecting);
    } else if (state.status == ReceiverConnectionStatus.connecting) {
      // Bağlantı kurulurken koptu, hata olarak kabul et
      state = state.copyWith(
        status: ReceiverConnectionStatus.error,
        errorMessage: 'Sinyal sunucusu bağlantısı kesildi.',
      );
    }
  }

  /// Mesajı kuyruğa ekler ve kuyruk işlemcisini başlatır
  void _enqueueMessage(Map<String, dynamic> message) {
    _messageQueue.add(message);
    _processQueue();
  }

  /// Kuyruktan sırayla mesajları işler (concurrent çalışma yok)
  Future<void> _processQueue() async {
    if (_processingMessage) return; // Zaten bir mesaj işleniyor
    _processingMessage = true;

    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.removeFirst();
      await _handleSignalingMessageInternal(message);
    }

    _processingMessage = false;
  }

  /// Sender'dan gelen sinyal mesajlarını işler
  Future<void> _handleSignalingMessageInternal(
    Map<String, dynamic> message,
  ) async {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (type == null || data == null) return;

    Logger.info('Sinyal mesajı alındı: $type');
    // ignore: avoid_print
    print('[DEBUG-RP] handleSignalingMessage: type=$type');

    switch (type) {
      case 'offer':
        await _handleOffer(data);
        break;
      case 'candidate':
        await _handleCandidate(data);
        break;
      case 'bye':
        await _handleBye();
        break;
    }
  }

  /// Sender'dan gelen SDP Offer'ı işler ve Answer döndürür
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      final sdp = data['sdp'] as String;
      final type = data['type'] as String;

      Logger.info('SDP Offer alındı, PeerConnection kuruluyor...');
      // ignore: avoid_print
      print('[DEBUG-RP] _handleOffer CALLED, creating PeerConnection...');

      // 1. Receiver için PeerConnection oluştur
      final pc = _webrtcService.peerConnection;
      if (pc == null) {
        throw Exception('PeerConnection oluşturulamadı veya başlatılmadı');
      }

      // 2. ICE Candidate'ları Sender'a gönder
      pc.onIceCandidate = (candidate) {
        _signalingClient.sendMessage({
          'type': 'candidate',
          'data': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      };

      // 3. Remote stream geldiğinde renderer'a bağla
      _webrtcService.onRemoteStream = (MediaStream stream) {
        Logger.info('Remote video stream alındı!');
        // ignore: avoid_print
        print('[DEBUG-RP] onRemoteStream FIRED! stream id: ${stream.id}');
        _streamReceiver.setRemoteStream(stream);
        state = state.copyWith(status: ReceiverConnectionStatus.connected);

        // Sesli bildirim
        SoundService.playConnected();
      };

      // DataChannel mesajlarını dinle (latency ölçümü + torch status için)
      _webrtcService.onDataChannelMessage = (message) {
        if (message.startsWith('timestamp:')) {
          final parts = message.split(':');
          if (parts.length == 2) {
            final sentOk = int.tryParse(parts[1]);
            if (sentOk != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              final latency = (now - sentOk) ~/ 2;
              state = state.copyWith(latencyMs: latency);
            }
          }
        } else if (message.startsWith('ping:')) {
          // ping:<id>:<timestamp> -> pong:<id>:<timestamp> cevabi dön
          final parts = message.split(':');
          if (parts.length == 3) {
            final pingId = parts[1];
            final originalTs = parts[2];
            _webrtcService.sendDataChannelMessage('pong:$pingId:$originalTs');
          }
        } else if (message.startsWith('status:')) {
          _handleRemoteStatus(message);
        }
      };

      // 4. ICE connection state değişikliklerini dinle
      _webrtcService.onIceConnectionState = (RTCIceConnectionState iceState) {
        _handleIceConnectionState(iceState);
      };

      // 5. Answer oluştur (içeride setRemoteDescription + createAnswer yapılır)
      final remoteOffer = RTCSessionDescription(sdp, type);
      final answer = await _webrtcService.createAnswer(remoteOffer);

      // 6. Remote description artık set edildi — bekleyen candidate'ları ekle
      _remoteDescriptionSet = true;
      await _flushPendingCandidates();

      if (answer != null) {
        _signalingClient.sendMessage({
          'type': 'answer',
          'data': {'sdp': answer.sdp, 'type': answer.type},
        });
        Logger.info('SDP Answer Sender\'a gönderildi');
        // ignore: avoid_print
        print('[DEBUG-RP] Answer SENT to Sender');
      } else {
        Logger.error('Answer oluşturulamadı!');
        // ignore: avoid_print
        print('[DEBUG-RP] ERROR: Answer is NULL!');
      }
    } catch (e, st) {
      Logger.error('Offer işlenirken hata', e, st);
      state = state.copyWith(
        status: ReceiverConnectionStatus.error,
        errorMessage: 'WebRTC bağlantı hatası: $e',
      );
    }
  }

  /// Sender'dan gelen ICE Candidate'ı ekler veya buffer'a alır
  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    final candidateStr = data['candidate'] as String;
    final sdpMid = data['sdpMid'] as String;
    final sdpMLineIndex = data['sdpMLineIndex'] as int;

    final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);

    if (_remoteDescriptionSet && _webrtcService.peerConnection != null) {
      // Remote description set — candidate'ı doğrudan ekle
      await _webrtcService.addIceCandidate(candidate);
    } else {
      // Henüz hazır değil — buffer'a al
      Logger.info(
        'ICE Candidate buffer\'a alındı (remote description henüz set edilmedi)',
      );
      _pendingCandidates.add(candidate);
    }
  }

  /// Bekleyen ICE candidate'ları PeerConnection'a ekler
  Future<void> _flushPendingCandidates() async {
    if (_pendingCandidates.isEmpty) return;

    Logger.info(
      '${_pendingCandidates.length} bekleyen ICE candidate ekleniyor...',
    );

    for (final candidate in _pendingCandidates) {
      await _webrtcService.addIceCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  /// Sender'dan gelen bye mesajını işler
  Future<void> _handleBye() async {
    Logger.info('Sender bağlantıyı sonlandırdı');
    await _resetWebRTC();
    state = state.copyWith(status: ReceiverConnectionStatus.idle);
    await SoundService.playDisconnected();
  }

  /// ICE connection state'i izler
  void _handleIceConnectionState(RTCIceConnectionState iceState) {
    Logger.info('ICE Connection State değişti: $iceState');
    switch (iceState) {
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        Logger.warning('ICE bağlantısı başarısız, yeniden deneniyor...');
        state = state.copyWith(status: ReceiverConnectionStatus.reconnecting);
        _resetWebRTC();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        Logger.warning('ICE bağlantısı koptu');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        Logger.info('ICE bağlantısı kapandı');
        break;
      default:
        break;
    }
  }

  /// Mirror (yatay çevirme) durumunu değiştirir
  void toggleMirror() {
    state = state.copyWith(isMirrored: !state.isMirrored);
    Logger.info('Mirror durumu: ${state.isMirrored}');
  }

  /// Zoom seviyesini ayarlar (1.0 - 5.0 arası)
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(1.0, 5.0);
    state = state.copyWith(zoomLevel: clampedZoom);
  }

  // ─── Fener Remote Control ───────────────────────────────────────

  /// Sender'dan gelen status mesajlarını işler (torch durumu vb.)
  void _handleRemoteStatus(String data) {
    final parts = data.split(':');
    // parts[0] = "status", parts[1] = hedef, parts[2] = değer
    if (parts.length >= 3 && parts[1] == 'torch') {
      switch (parts[2]) {
        case 'on':
          state = state.copyWith(
            isTorchOn: true,
            isTorchAvailable: true,
            isTorchLoading: false,
          );
        case 'off':
          state = state.copyWith(
            isTorchOn: false,
            isTorchAvailable: true,
            isTorchLoading: false,
          );
        case 'unavailable':
          state = state.copyWith(
            isTorchAvailable: false,
            isTorchLoading: false,
          );
        case 'error':
          state = state.copyWith(isTorchLoading: false);
          Logger.warning('Fener hatası (Sender tarafından bildirildi)');
      }
    }
  }

  /// Receiver tarafında fener toggle komutu gönderir (DataChannel üzerinden)
  void toggleTorch() {
    // Debounce: loading sırasında ikinci basışı yoksay
    if (state.isTorchLoading) return;

    state = state.copyWith(isTorchLoading: true);

    _webrtcService.sendDataChannelMessage('cmd:torch:toggle');

    // 500ms içinde status yanıtı gelmezse loading'i kapat (timeout/rollback)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state.isTorchLoading) {
        state = state.copyWith(isTorchLoading: false);
        Logger.warning('Torch toggle yanıtı gelmedi (timeout)');
      }
    });
  }

  /// Bağlantıyı bilinçli olarak sonlandırır
  Future<void> disconnect() async {
    _signalingClient.sendMessage({'type': 'bye', 'data': <String, dynamic>{}});
    await _resetWebRTC();
    await _signalingClient.disconnect();
    state = state.copyWith(status: ReceiverConnectionStatus.idle);
    await SoundService.playDisconnected();
  }

  /// WebRTC bağlantısını sıfırlar
  Future<void> _resetWebRTC() async {
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();
    await _webrtcService.dispose();
  }

  /// Tüm kaynakları temizler
  Future<void> _cleanup() async {
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _webrtcService.dispose();
    await _streamReceiver.dispose();
    await _signalingClient.dispose();
  }
}
