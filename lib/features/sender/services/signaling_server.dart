import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/logger.dart';

/// Gönderici cihazda (Kamera) çalışan yerel WebSocket sinyal sunucusu.
/// Bu sunucu sadece bir istemciyi kabul eder ve WebRTC sinyal verilerini
/// (SDP Offer/Answer ve ICE Candidate) karşılıklı taşır.
class SignalingServer {
  HttpServer? _server;
  WebSocket? _clientSocket;

  /// Yeni bir sinyal mesajı geldiğinde tetiklenen stream
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// İstemci (Alıcı) bağlandığında haber veren state
  final _clientConnectedController = StreamController<bool>.broadcast();
  Stream<bool> get onClientConnected => _clientConnectedController.stream;

  /// Sunucuyu başlatır
  Future<void> start({int port = 8765}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      Logger.info('Sinyal sunucusu $_server.address:$port üzerinde başlatıldı');

      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/ws') {
          // CSWH (Cross-Site WebSocket Hijacking) koruması
          final origin = request.headers['origin']?.first;
          if (origin != null) {
            final originHost = Uri.tryParse(origin)?.host;
            final requestedHost = request.requestedUri.host;
            if (originHost != requestedHost) {
              Logger.warning(
                'CSWH attempt blocked: Origin $originHost does not match requested host $requestedHost',
                'SignalingServer',
              );
              request.response.statusCode = HttpStatus.forbidden;
              await request.response.close();
              return;
            }
          }

          // WebSockets'e yükseltme isteği
          final socket = await WebSocketTransformer.upgrade(request);
          _handleClientConnection(socket);
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });
    } catch (e, st) {
      Logger.error('Sinyal sunucusu başlatılamadı', e, st);
    }
  }

  /// Yeni istemci bağlantısını ele alır (Mevcut varsa eskisini kapatır)
  void _handleClientConnection(WebSocket socket) {
    if (_clientSocket != null) {
      Logger.warning('Yeni bir istemci bağlandı, eski bağlantıyı kapatıyorum');
      _clientSocket!.close(
        WebSocketStatus.normalClosure,
        'New client connected',
      );
    }

    _clientSocket = socket;
    _clientConnectedController.add(true);
    Logger.info('İstemci (Alıcı) bağlandı!');

    // Mesajları dinle
    _clientSocket!.listen(
      (dynamic data) {
        if (data is String) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            _messageController.add(json);
          } catch (e) {
            Logger.error('Geçersiz sinyal mesajı formatı', e);
          }
        }
      },
      onDone: () {
        Logger.info('İstemci bağlantısı koptu');
        _clientConnectedController.add(false);
        _clientSocket = null;
      },
      onError: (dynamic error) {
        Logger.error('İstemci bağlantısında hata', error);
        _clientConnectedController.add(false);
        _clientSocket = null;
      },
    );
  }

  /// Alıcıya SDP Offer, Answer veya ICE candidate gönderir
  void sendMessage(Map<String, dynamic> data) {
    if (_clientSocket != null && _clientSocket!.readyState == WebSocket.open) {
      final encoded = jsonEncode(data);
      // ignore: avoid_print
      print(
        '[DEBUG-SERVER] sendMessage: type=${data['type']}, len=${encoded.length}',
      );
      _clientSocket!.add(encoded);
    } else {
      Logger.warning('Mesaj gönderilemedi: İstemci bağlı değil');
      // ignore: avoid_print
      print(
        '[DEBUG-SERVER] sendMessage FAILED: client=${_clientSocket != null}, state=${_clientSocket?.readyState}',
      );
    }
  }

  /// Sunucuyu durdurur ve kanalları kapatır
  Future<void> stop() async {
    if (_clientSocket != null) {
      await _clientSocket!.close(
        WebSocketStatus.normalClosure,
        'Sunucu kapaniyor',
      );
      _clientSocket = null;
    }
    await _server?.close(force: true);
    _server = null;
    Logger.info('Sinyal sunucusu durduruldu');
  }

  /// Servis imha edildiğinde
  void dispose() {
    stop();
    _messageController.close();
    _clientConnectedController.close();
  }
}
