import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Alıcının eşleşmesi için QR kod oluşturan bileşen
class QrDisplay extends StatelessWidget {
  /// Cihazın yerel IP adresi
  final String ipAddress;

  /// WebSocket sunucu portu
  final int port;

  /// Kimlik doğrulama token'ı
  final String authToken;

  /// Sabit yapıcı
  const QrDisplay({super.key, required this.ipAddress, required this.port, required this.authToken});

  @override
  Widget build(BuildContext context) {
    // Alıcının QR okuyucu ile alacağı veri formatı
    final qrData = '$ipAddress:$port:$authToken';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bağlanmak için bu kodu okutun',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'IP: $ipAddress',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Şifre: $authToken',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
