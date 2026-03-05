/// WebSocket ağ üzerinden iletilen standart sinyal mesajı.
/// Sender ve Receiver arasında offer/answer/candidate/bye mesajları taşır.
class SignalingMessage {
  /// Mesajın türü (offer, answer, candidate, bye)
  final String type;

  /// Mesaj içeriği
  final Map<String, dynamic> data;

  /// Sabit yapıcı
  const SignalingMessage({required this.type, required this.data});

  /// JSON'dan SignalingMessage oluşturur
  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  /// SignalingMessage'ı JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {'type': type, 'data': data};
  }
}
