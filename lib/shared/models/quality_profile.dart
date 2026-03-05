/// Video yayın kalite profilleri
enum QualityProfile {
  /// Dengeli: 720p 30fps — Pil tasarrufu veya zayıf ağ koşulları
  balanced(
    width: 1280,
    height: 720,
    fps: 30,
    minBitrate: 2000000,
    maxBitrate: 5000000,
    label: 'Dengeli (720p)',
  ),

  /// Yüksek: 1080p 30fps — Çoğu kullanım senaryosu için
  high(
    width: 1920,
    height: 1080,
    fps: 30,
    minBitrate: 6000000,
    maxBitrate: 12000000,
    label: 'Yüksek (1080p)',
  ),

  /// Ultra: 1080p 60fps — Ayna akıcılığı için (Sabit WiFi 6 veya LAN gerekir)
  ultra(
    width: 1920,
    height: 1080,
    fps: 60,
    minBitrate: 10000000,
    maxBitrate: 20000000,
    label: 'Ultra (1080p 60fps)',
  ),

  /// Maksimum Netlik: 1440p 30fps — Düşük hareket/yüksek detay gereken senaryolar
  maxClarity(
    width: 2560,
    height: 1440,
    fps: 30,
    minBitrate: 15000000,
    maxBitrate: 30000000,
    label: 'Maks Netlik (1440p)',
  );

  /// Sabit Yapıcı
  const QualityProfile({
    required this.width,
    required this.height,
    required this.fps,
    required this.minBitrate,
    required this.maxBitrate,
    required this.label,
  });

  /// Video genişliği
  final int width;

  /// Video yüksekliği
  final int height;

  /// Saniyedeki kare sayısı (Frame Rate)
  final int fps;

  /// Hedef minimum veri hızı (bps)
  final int minBitrate;

  /// Hedef maksimum veri hızı (bps)
  final int maxBitrate;

  /// Kullanıcı arayüzünde gösterilecek isim
  final String label;

  /// String'den QualityProfile'a dönüşüm
  static QualityProfile fromString(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => ultra);
  }
}
