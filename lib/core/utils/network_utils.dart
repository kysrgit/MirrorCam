import 'dart:io';

import 'package:flutter/services.dart';

import 'logger.dart';

/// Utility methods for network operations.
class NetworkUtils {
  /// Gets the local IPv4 address of the device.
  /// Returns null if no suitable address is found.
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // İlk önce Wi-Fi ağlarını (wlan, en0) bulmaya çalış
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('en0')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }

      // Eğer Wi-Fi bulunamazsa herhangi bir kullanılabilir adresi döndür
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
      return null;
    } catch (e, st) {
      Logger.error('Failed to get local IP address', e, st);
      return null;
    }
  }

  static const MethodChannel _wifiChannel = MethodChannel('com.mirrorcam/wifi');

  /// Android cihazlarda WiFi yüksek performans modunu açar (Wakelock).
  /// Düşük gecikmeli WebRTC akışı için çok önemlidir (~30ms gecikme düşürür).
  static Future<void> enableWifiHighPerformance() async {
    try {
      await _wifiChannel.invokeMethod('enableHighPerformance');
      Logger.info('WiFi High Performance Mode enabled.');
    } catch (e) {
      Logger.warning('Failed to enable WiFi High Performance Mode: $e');
    }
  }

  /// WiFi yüksek performans modunu kapatır (Pil tasarrufu).
  static Future<void> disableWifiHighPerformance() async {
    try {
      await _wifiChannel.invokeMethod('disableHighPerformance');
      Logger.info('WiFi High Performance Mode disabled.');
    } catch (e) {
      Logger.warning('Failed to disable WiFi High Performance Mode: $e');
    }
  }
}
