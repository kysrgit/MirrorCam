/// Gecikme Modları
enum LatencyMode {
  /// Ultra Düşük Gecikme (0ms jitter buffer hedefini zorlar).
  /// Sadece kusursuz LAN/WiFi 6 ortamlarında (ping < 5ms) önerilir.
  ultraLow,

  /// Düşük Gecikme (20ms jitter buffer hedefini zorlar).
  /// Çoğu lokal ağ, hotspot ve stabil 5GHz WiFi ortamları için önerilir.
  low,

  /// Normal Gecikme (50ms jitter buffer hedefini zorlar).
  /// 2.4GHz WiFi veya stabil olmayan ağlar için önerilir.
  normal;

  /// Modun temsil ettiği Jitter Buffer süresi
  Duration get jitterTarget {
    switch (this) {
      case LatencyMode.ultraLow:
        return Duration.zero;
      case LatencyMode.low:
        return const Duration(milliseconds: 20);
      case LatencyMode.normal:
        return const Duration(milliseconds: 50);
    }
  }

  /// Kullanıcı arayüzünde gösterilecek isim
  String get label {
    switch (this) {
      case LatencyMode.ultraLow:
        return 'Ultra Düşük (0ms)';
      case LatencyMode.low:
        return 'Düşük (20ms) - Önerilen';
      case LatencyMode.normal:
        return 'Normal (50ms)';
    }
  }

  /// String'den LatencyMode'a dönüşüm için ardıl metod
  static LatencyMode fromString(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => ultraLow);
  }
}
