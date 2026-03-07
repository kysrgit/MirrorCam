import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/utils/logger.dart';

/// Receiver tarafında Sender'ın sinyal sunucusuna bağlanan WebSocket istemcisi.
/// Otomatik yeniden bağlanma (exponential backoff) desteği içerir.
class SignalingClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  /// Gelen sinyal mesajlarını yayınlayan stream
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Bağlantı durumu değişikliklerini yayınlayan stream
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionState => _connectionStateController.stream;

  /// Bağlantı bilgileri
  String? _ip;
  int? _port;
  bool _isConnected = false;
  bool _intentionalDisconnect = false;

  /// Yeniden bağlanma sayacı
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  /// Mevcut bağlantı durumu
  bool get isConnected => _isConnected;

  /// Sender'ın sinyal sunucusuna WebSocket bağlantısı kurar
  Future<void> connect(String ip, int port) async {
    _ip = ip;
    _port = port;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _connect();
  }

  /// Asıl bağlantı kurma işlemi
  Future<void> _connect() async {
    try {
      // Varsa eski bağlantıyı temizle
      await _subscription?.cancel();
      unawaited(_channel?.sink.close() ?? Future<void>.value());

      final uri = Uri.parse('ws://$_ip:$_port/ws');
      Logger.info('WebSocket bağlantısı kuruluyor: $uri');

      _channel = WebSocketChannel.connect(uri);

      // Bağlantının kurulmasını bekle
      await _channel!.ready;

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      Logger.info('WebSocket bağlantısı başarıyla kuruldu');
      Logger.info('[DEBUG-SC] WebSocket CONNECTED to $uri');

      // Mesajları dinle
      _subscription = _channel!.stream.listen(
        (dynamic data) {
          Logger.info('[DEBUG-SC] RAW data received: ${data.runtimeType} => $data');
          if (data is String) {
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              Logger.info('[DEBUG-SC] Parsed message type: ${json['type']}');
              _messageController.add(json);
            } catch (e) {
              Logger.error('Geçersiz sinyal mesajı formatı', e);
            }
          }
        },
        onDone: () {
          Logger.info('WebSocket bağlantısı kapandı');
          _onDisconnected();
        },
        onError: (dynamic error) {
          Logger.error('WebSocket bağlantısında hata', error);
          _onDisconnected();
        },
      );
    } catch (e, st) {
      Logger.error('WebSocket bağlantısı kurulamadı', e, st);
      _isConnected = false;
      _connectionStateController.add(false);
      unawaited(_attemptReconnect());
    }
  }

  /// Bağlantı koptuğunda çağrılır
  void _onDisconnected() {
    _isConnected = false;
    _connectionStateController.add(false);

    if (!_intentionalDisconnect) {
      _attemptReconnect();
    }
  }

  /// Exponential backoff ile yeniden bağlanmayı dener (1s → 2s → 4s, max 3 deneme)
  Future<void> _attemptReconnect() async {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.warning(
        'Maksimum yeniden bağlanma denemesine ulaşıldı ($_maxReconnectAttempts)',
      );
      _messageController.addError(
        Exception(
          'Gönderici cihaza bağlanılamadı. IP: $_ip. Aynı WiFi ağında olduğunuzdan emin olun.',
        ),
      );
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: 1 << (_reconnectAttempts - 1),
    ); // 1s, 2s, 4s
    Logger.info(
      'Yeniden bağlanma denemesi $_reconnectAttempts/$_maxReconnectAttempts '
      '(${delay.inSeconds}s sonra)',
    );

    await Future<void>.delayed(delay);

    if (!_intentionalDisconnect && !_isConnected) {
      await _connect();
    }
  }

  /// Sinyal mesajı gönderir
  void sendMessage(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      Logger.warning('Mesaj gönderilemedi: WebSocket bağlı değil');
    }
  }

  /// Bağlantıyı bilinçli olarak kapatır (yeniden bağlanma tetiklenmez)
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }
    Logger.info('WebSocket bağlantısı kapatıldı');
  }

  /// Tüm kaynakları temizler
  Future<void> dispose() async {
    _intentionalDisconnect = true;
    await disconnect();
    await _messageController.close();
    await _connectionStateController.close();
  }
}
