import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/logger.dart';

/// QR kod tarayıcı ve manuel IP girişi widget'ı.
/// Sender'ın QR kodundaki IP:PORT bilgisini okur.
class QrScanner extends StatefulWidget {
  /// Başarılı taramada IP ve port bilgisi ile çağrılır
  final void Function(String ip, int port) onScanned;

  /// Sabit yapıcı
  const QrScanner({super.key, required this.onScanned});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _ipController = TextEditingController();
  bool _isManualMode = false;
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  /// QR koddan gelen veriyi parse eder (IP:PORT formatı)
  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      final result = _parseIpPort(value);
      if (result != null) {
        _hasScanned = true;
        Logger.info('QR koddan IP bilgisi alındı: $value');
        widget.onScanned(result.$1, result.$2);
        return;
      } else {
        setState(() {
          _errorMessage = 'Geçersiz QR kod formatı: $value';
        });
      }
    }
  }

  /// IP:PORT formatını parse eder (Sender'ın qr_display.dart ile uyumlu)
  (String, int)? _parseIpPort(String data) {
    final parts = data.trim().split(':');
    if (parts.length != 2) return null;

    final ip = parts[0];
    final port = int.tryParse(parts[1]);

    if (port == null) return null;
    if (!_isValidIp(ip)) return null;

    return (ip, port);
  }

  /// IPv4 adres formatı doğrulama
  bool _isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  /// Manuel IP ile bağlanma
  void _connectManually() {
    final input = _ipController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Lütfen IP adresi girin');
      return;
    }

    // IP:PORT veya sadece IP kabul et (port yoksa varsayılan 8765)
    final result = _parseIpPort(input.contains(':') ? input : '$input:8765');

    if (result != null) {
      widget.onScanned(result.$1, result.$2);
    } else {
      setState(() => _errorMessage = 'Geçersiz IP adresi: $input');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Gönderici cihazın QR kodunu okutun',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),

        // QR Tarayıcı veya Manuel Giriş
        Expanded(
          child: _isManualMode
              ? _buildManualInput(context)
              : _buildQrScanner(context),
        ),

        // Hata mesajı
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Mod değiştirme butonu
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isManualMode = !_isManualMode;
                _errorMessage = null;
              });
            },
            icon: Icon(_isManualMode ? Icons.qr_code : Icons.keyboard),
            label: Text(
              _isManualMode ? 'QR Kod ile Bağlan' : 'Manuel IP Girişi',
            ),
          ),
        ),
      ],
    );
  }

  /// QR kod tarayıcı görünümü
  Widget _buildQrScanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MobileScanner(
          controller: _scannerController,
          onDetect: _handleBarcode,
        ),
      ),
    );
  }

  /// Manuel IP girişi görünümü
  Widget _buildManualInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 24),
          Text(
            'Gönderici cihazın IP adresini girin',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'IP Adresi',
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Icons.language),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _connectManually(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connectManually,
              icon: const Icon(Icons.cast_connected),
              label: const Text('Bağlan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
