import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/utils/logger.dart';
import '../models/quality_profile.dart';

/// Ortak WebRTC işlemleri (PeerConnection yönetimi ve optimizasyon).
/// Hem Sender hem Receiver tarafından kullanılır.
class WebRTCService {
  // ⚡ Performans optimizasyonu: Döngü içinde (örn. SDP satırlarında) tekrar tekrar
  // derlenmesini önlemek için RegExp objesini static final olarak tanımlıyoruz.
  static final _profileLevelIdRegex = RegExp(r'profile-level-id=[0-9a-fA-F]+');

  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  /// Remote stream geldiğinde çağrılacak callback
  void Function(MediaStream stream)? onRemoteStream;

  /// ICE connection state değiştiğinde çağrılacak callback
  void Function(RTCIceConnectionState state)? onIceConnectionState;

  /// DataChannel üzerinden mesaj geldiğinde çağrılacak callback
  void Function(String message)? onDataChannelMessage;

  /// DataChannel açıldığında çağrılacak callback
  void Function()? onDataChannelOpen;

  /// Sender için PeerConnection oluşturur (sadece video gönderir, almaz)
  Future<RTCPeerConnection?> createConnection() async {
    try {
      final configuration = <String, dynamic>{
        'iceServers': <Map<String, dynamic>>[],
        'sdpSemantics': 'unified-plan',
        'iceCandidatePoolSize': 0, // ICE timeout optimization
      };

      final constraints = <String, dynamic>{
        'mandatory': {
          'OfferToReceiveAudio': 'false',
          'OfferToReceiveVideo': 'false',
        },
        'optional': [
          {'DtlsSrtpKeyAgreement': 'true'},
          // Google-spesifik düşük gecikme flag'leri (sadece Sender'da - Encoder için)
          {'googHighStartBitrate': '4000'},
          {'googPayloadPadding': 'true'},
          {'googScreencastMinBitrate': '4000'},
          {'googCpuOveruseDetection': 'false'},
          {'googCpuOveruseEncodeUsage': 'false'},
          {'googCpuUnderuseThreshold': '55'},
        ],
      };

      peerConnection = await createPeerConnection(configuration, constraints);

      // ⚡ Latency ölçümü için ultra-düşük gecikme DataChannel (negotiated)
      final pingChannelConfig = RTCDataChannelInit()
        ..ordered =
            false // Sıralama gereksiz, gecikmeyi düşürür
        ..maxRetransmits =
            0 // Kaybolan paketi tekrar gönderme
        ..protocol =
            'ping' // Ayrı bir kanal olduğunu belirt
        ..negotiated =
            true // Her iki taraf da aynı ID ile açar, setup süresi -1 RTT
        ..id = 1; // Sabit ID (negotiated için zorunlu)

      dataChannel = await peerConnection!.createDataChannel(
        'latency',
        pingChannelConfig,
      );
      dataChannel!.onMessage = (RTCDataChannelMessage message) {
        if (message.type == MessageType.text) {
          onDataChannelMessage?.call(message.text);
        }
      };
      dataChannel!.onDataChannelState = (RTCDataChannelState dcState) {
        if (dcState == RTCDataChannelState.RTCDataChannelOpen) {
          Logger.info('DataChannel açıldı');
          onDataChannelOpen?.call();
        }
      };

      _setupConnectionStateListeners();
      Logger.info('RTCPeerConnection başarıyla oluşturuldu (Sender)');
      return peerConnection;
    } catch (e, st) {
      Logger.error('RTCPeerConnection oluşturulamadı', e, st);
      return null;
    }
  }

  /// Receiver için PeerConnection oluşturur (video alır, göndermez)
  Future<RTCPeerConnection?> createConnectionForReceiver() async {
    try {
      final configuration = <String, dynamic>{
        'iceServers': <Map<String, dynamic>>[],
        'sdpSemantics': 'unified-plan',
        'iceCandidatePoolSize': 0,
      };

      final constraints = <String, dynamic>{
        'mandatory': {
          'OfferToReceiveAudio': 'false',
          'OfferToReceiveVideo': 'true',
        },
        'optional': [
          {'DtlsSrtpKeyAgreement': 'true'},
        ],
      };

      peerConnection = await createPeerConnection(configuration, constraints);

      // ⚡ Receiver tarafında da aynı negotiated DataChannel'ı oluştur
      final pingChannelConfig = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 0
        ..protocol = 'ping'
        ..negotiated = true
        ..id = 1;

      dataChannel = await peerConnection!.createDataChannel(
        'latency',
        pingChannelConfig,
      );
      dataChannel!.onMessage = (RTCDataChannelMessage message) {
        if (message.type == MessageType.text) {
          onDataChannelMessage?.call(message.text);
        }
      };

      _setupConnectionStateListeners();
      _setupTrackListener();
      Logger.info('RTCPeerConnection başarıyla oluşturuldu (Receiver)');
      return peerConnection;
    } catch (e, st) {
      Logger.error('Receiver RTCPeerConnection oluşturulamadı', e, st);
      return null;
    }
  }

  /// ICE ve connection state listener'larını kurar
  void _setupConnectionStateListeners() {
    peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      Logger.info('ICE Connection State: $state');
      onIceConnectionState?.call(state);
    };
  }

  /// onTrack event'ini dinleyerek remote stream'i callback'e iletir
  void _setupTrackListener() {
    peerConnection?.onTrack = (RTCTrackEvent event) {
      Logger.info('Remote track alındı: ${event.track.kind}');

      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams[0]);
      }
      if (event.track.kind == 'video') {
        try {
          if (event.receiver != null) {
            (event.receiver as dynamic).jitterBufferTarget = Duration.zero;
          }
          Logger.info('Jitter buffer → zero (hardcoded)');
        } catch (e) {
          Logger.warning('Jitter buffer ayarlanamadı: $e');
        }
      }
    };
  }

  /// SDP Optimizasyonu: H.264 önceliği (High Profile), VP8/VP9 çıkarma, bitrate ayarları
  String optimizeSdp(
    String sdp, {
    int startBitrate = 4000,
    int maxBitrate = 8000,
  }) {
    final lines = sdp.split('\r\n');
    final optimizedLines = <String>[];
    String? h264PayloadType;

    // 1. H264 Payload ID'sini bul
    for (final line in lines) {
      if (line.startsWith('a=rtpmap:') && line.contains('H264/90000')) {
        h264PayloadType = line.substring(9).split(' ')[0];
        break;
      }
    }

    bool inVideo = false;
    for (var line in lines) {
      if (line.startsWith('m=video')) {
        inVideo = true;
      } else if (line.startsWith('m=audio') ||
          line.startsWith('m=application')) {
        inVideo = false;
      }

      // Audio section clean-up
      if (line.startsWith('a=rtpmap:') && line.contains('opus/48000')) {
        line = line.replaceFirst('opus/48000', 'opus/48000/2');
      }
      if (line.startsWith('a=fmtp:') && line.contains('opus')) {
        if (!line.contains('stereo=')) {
          line = '$line; stereo=0; useinbandfec=0';
        }
      }

      // VP8/VP9 çıkarma (H264 varsa)
      if (h264PayloadType != null &&
          (line.toUpperCase().contains('VP8') ||
              line.toUpperCase().contains('VP9'))) {
        continue;
      }

      // Sadece H.264 payload'ları bırak (m=video satırı için)
      if (line.startsWith('m=video') && h264PayloadType != null) {
        final parts = line.split(' ');
        // 0: m=video, 1: port, 2: protocol, 3+: payloads
        line = '${parts[0]} ${parts[1]} ${parts[2]} $h264PayloadType';
      }

      optimizedLines.add(line);

      // Max bitrate satırı
      if (inVideo && line.startsWith('c=IN')) {
        optimizedLines.add('b=AS:$maxBitrate');
      }

      // H.264 fmtp parametrelerini Google spesifik değerler ve High Profile ile güncelle
      if (h264PayloadType != null &&
          line.startsWith('a=fmtp:$h264PayloadType')) {
        String newLine = line;

        // profile-level-id değiştir (High Profile)
        if (newLine.contains('profile-level-id=')) {
          newLine = newLine.replaceAll(
            _profileLevelIdRegex,
            'profile-level-id=640c1f',
          );
        } else {
          newLine = '$newLine; profile-level-id=640c1f';
        }

        // Bitrate ve cpu ayarları
        if (!newLine.contains('x-google-start-bitrate')) {
          newLine =
              '$newLine; x-google-start-bitrate=$startBitrate; x-google-min-bitrate=${startBitrate ~/ 2}; x-google-max-bitrate=$maxBitrate; googCpuOveruseDetection=false';
        }

        optimizedLines[optimizedLines.length - 1] = newLine;
      }
    }

    return optimizedLines.join('\r\n');
  }

  /// SDP Offer oluştur, optimizasyonları yap ve setLocalDescription uygula
  Future<RTCSessionDescription?> createOffer(
    MediaStream localStream, {
    int startBitrate = 4000,
    int maxBitrate = 8000,
  }) async {
    if (peerConnection == null) return null;

    try {
      for (final track in localStream.getTracks()) {
        await peerConnection!.addTrack(track, localStream);
      }

      // NOTE: Sender params configuration is now handled in applyStreamConstraints
      // which should be called externally after createOffer/setLocalDescription.

      var offer = await peerConnection!.createOffer();
      final originalOffer = offer;

      // SDP Optimizasyonu Aktif
      if (offer.sdp != null) {
        try {
          final optimizedSdp = optimizeSdp(
            offer.sdp!,
            startBitrate: startBitrate,
            maxBitrate: maxBitrate,
          );
          offer = RTCSessionDescription(optimizedSdp, offer.type);
        } catch (e) {
          Logger.error('SDP Optimizasyonu hata verdi, atlanıyor.', e);
          offer = originalOffer;
        }
      }

      try {
        await peerConnection!.setLocalDescription(offer);
      } catch (e) {
        Logger.warning(
          'Optimize edilmiş SDP kabul edilmedi, orijinal SDP\'ye dönülüyor. Hata: $e',
        );
        await peerConnection!.setLocalDescription(originalOffer);
        offer = originalOffer;
      }

      Logger.info('SDP Offer başarıyla oluşturuldu');

      return offer;
    } catch (e, st) {
      Logger.error('Offer oluşturulurken hata', e, st);
      return null;
    }
  }

  /// Receiver tarafında: Remote Offer'ı set edip SDP Answer oluşturur
  Future<RTCSessionDescription?> createAnswer(
    RTCSessionDescription remoteOffer,
  ) async {
    if (peerConnection == null) return null;

    try {
      await peerConnection!.setRemoteDescription(remoteOffer);
      Logger.info('Remote offer ayarlandı, answer oluşturuluyor...');

      var answer = await peerConnection!.createAnswer();
      final originalAnswer = answer;

      // SDP Optimizasyonu Aktif
      if (answer.sdp != null) {
        try {
          final optimizedSdp = optimizeSdp(answer.sdp!);
          answer = RTCSessionDescription(optimizedSdp, answer.type);
        } catch (e) {
          Logger.error('SDP Optimizasyonu hata verdi, atlanıyor.', e);
          answer = originalAnswer;
        }
      }

      try {
        await peerConnection!.setLocalDescription(answer);
      } catch (e) {
        Logger.warning(
          'Optimize edilmiş SDP Answer kabul edilmedi, orijinal SDP\'ye dönülüyor. Hata: $e',
        );
        await peerConnection!.setLocalDescription(originalAnswer);
        answer = originalAnswer;
      }
      Logger.info('SDP Answer başarıyla oluşturuldu');

      return answer;
    } catch (e, st) {
      Logger.error('Answer oluşturulurken hata', e, st);
      return null;
    }
  }

  /// Karşı taraftan (Receiver) gelen Answer'ı ayarlar (Sender tarafı kullanır)
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await peerConnection?.setRemoteDescription(description);
      Logger.info('Remote description başarıyla ayarlandı');
    } catch (e, st) {
      Logger.error('Remote description ayarlanamadı', e, st);
    }
  }

  /// Karşı taraftan gelen ICE candidate'ı ekler (Filtreleme uygular)
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      // ICE candidate filtering
      final candStr = candidate.candidate ?? '';
      if (candStr.contains('typ srflx') || candStr.contains('typ relay')) {
        Logger.info('Filtered ICE candidate: $candStr');
        return; // Sadece local "host" tipi candidate'ları kabul et
      }

      await peerConnection?.addCandidate(candidate);
      Logger.info('ICE Candidate başarıyla eklendi');
    } catch (e, st) {
      Logger.error('ICE Candidate eklenemedi', e, st);
    }
  }

  /// DataChannel mesajı gönderir
  void sendDataChannelMessage(String message) {
    if (dataChannel != null &&
        dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  /// QualityProfile'a göre encoder parametrelerini ayarlar
  Future<void> applyStreamConstraints(QualityProfile profile) async {
    if (peerConnection == null) return;

    final senders = await peerConnection!.getSenders();
    for (final sender in senders) {
      if (sender.track?.kind == 'video') {
        final params = sender.parameters;

        if (params.encodings != null) {
          for (final encoding in params.encodings!) {
            encoding.maxBitrate = profile.maxBitrate;
            encoding.minBitrate = profile.minBitrate;
            encoding.maxFramerate = profile.fps;
            encoding.scaleResolutionDownBy = 1.0; // Asla çözünürlük düşürme
          }
        }

        // Çözünürlükten ödün verme, gerekirse takılma olsun (Ayna için netlik önemli)
        params.degradationPreference =
            RTCDegradationPreference.MAINTAIN_RESOLUTION;

        try {
          await sender.setParameters(params);
          Logger.info(
            'Stream constraints applied: ${profile.label} '
            '(${profile.minBitrate ~/ 1000000}-${profile.maxBitrate ~/ 1000000} Mbps)',
          );
        } catch (e) {
          Logger.warning('Could not apply stream constraints: $e');
        }
      }
    }
  }

  /// Tüm kaynakları temizler
  Future<void> dispose() async {
    onRemoteStream = null;
    onIceConnectionState = null;
    onDataChannelMessage = null;
    onDataChannelOpen = null;
    await dataChannel?.close();
    dataChannel = null;

    await peerConnection?.close();
    peerConnection = null;

    Logger.info('RTCPeerConnection kapatıldı');
  }
}
