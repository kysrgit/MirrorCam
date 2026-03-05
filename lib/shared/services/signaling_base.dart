/// Sinyalleşme için temel sınıf
abstract class SignalingBase {
  /// WebSocket bağlantısını başlatır
  void connect();

  /// WebSocket bağlantısını kapatır
  void disconnect();
}
