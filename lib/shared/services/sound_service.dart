import 'package:flutter/services.dart';

import '../../../core/utils/logger.dart';

/// Basit ve yerleşik ses & titreşim geri bildirimi servisi.
/// Ekstra paket yüklemeden [SystemSound] ve [HapticFeedback] kullanır.
class SoundService {
  /// Bağlantı kurulduğunda çalacak ses (kısa bip + hafif titreşim)
  static Future<void> playConnected() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
      Logger.info('Connected sound played');
    } catch (e) {
      Logger.error('Failed to play connected sound', e);
    }
  }

  /// Bağlantı kesildiğinde veya hata olduğunda çalacak ses/titreşim (ağır titreşim)
  static Future<void> playDisconnected() async {
    try {
      // Hata veya kopma durumunda daha belirgin bir titreşim
      await HapticFeedback.heavyImpact();
      Logger.info('Disconnected sound played');
    } catch (e) {
      Logger.error('Failed to play disconnected sound', e);
    }
  }
}
