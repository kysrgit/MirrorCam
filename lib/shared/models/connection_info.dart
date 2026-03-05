/// WebRTC veya WebSocket bağlantı bilgileri
class ConnectionInfo {
  /// Cihaz IP adresi
  final String ipAddress;

  /// Cihazın port numarası
  final int port;

  /// Sabit yapıcı
  const ConnectionInfo({required this.ipAddress, required this.port});
}
