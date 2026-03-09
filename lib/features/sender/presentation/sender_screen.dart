import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/utils/permission_utils.dart';
import '../../../../shared/widgets/connection_info_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/sender_provider.dart';
import 'widgets/qr_display.dart';

/// Gönderici ekranı ana widget'ı
class SenderScreen extends ConsumerStatefulWidget {
  /// Sabit yapıcı
  const SenderScreen({super.key});

  @override
  ConsumerState<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends ConsumerState<SenderScreen>
    with WidgetsBindingObserver {
  bool _showConnectionInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ekranın kapanmasını engelle
    WakelockPlus.enable();
    // Status bar'ı gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Yatay dönüşe izin ver
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    // Geri getir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uygulama arka plana alındı. Kamera yayını yavaşlayabilir veya durabilir.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bağlantı durumu değiştiğinde bağlantı bilgi kartını göster
    ref.listen<SenderState>(senderNotifierProvider, (previous, next) {
      if (previous?.status != ConnectionStatus.connected &&
          next.status == ConnectionStatus.connected) {
        setState(() {
          _showConnectionInfo = true;
        });
      }
    });

    final senderState = ref.watch(senderNotifierProvider);
    final notifier = ref.read(senderNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera (Gönderici)'),
        leading: BackButton(
          onPressed: () {
            notifier.disconnect();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ana Gövde: QR veya Durum Göstergesi
            Center(child: _buildMainContent(senderState, notifier)),

            // Kamera Önizleme (Sağ üst köşe)
            if (senderState.localRenderer != null)
              Positioned(
                top: 16,
                right: 16,
                width: 120,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white38, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      senderState.localRenderer!,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false, // Arka kamera için mirror kapalı
                    ),
                  ),
                ),
              ),

            // Bağlantı Bilgi Kartı
            if (_showConnectionInfo)
              ConnectionInfoCard(
                ipAddress: senderState.localIp ?? '',
                qualityProfile: ref
                    .watch(settingsNotifierProvider)
                    .qualityProfile,
                latencyMs: senderState.latencyMs,
                onDismiss: () {
                  if (mounted) {
                    setState(() {
                      _showConnectionInfo = false;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(SenderState state, SenderNotifier notifier) {
    if (state.status == ConnectionStatus.initializing) {
      return const CircularProgressIndicator();
    }

    if (state.status == ConnectionStatus.error) {
      final isPermissionError =
          state.errorMessage?.contains('Kamera izni') ?? false;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              state.errorMessage ?? 'Bilinmeyen Hata',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (isPermissionError) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                PermissionUtils.openSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ayarlara Git'),
            ),
          ],
        ],
      );
    }

    if (state.status == ConnectionStatus.connected) {
      final settings = ref.watch(settingsNotifierProvider);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          Text(
            'Alıcı Başarıyla Bağlandı!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Kamera akışı şu anda iletiliyor.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Durum İkonları
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                if (state.isTorchAvailable) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isTorchOn
                            ? Icons.flashlight_on
                            : Icons.flashlight_off,
                        color: state.isTorchOn ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isTorchOn ? 'Fener Açık' : 'Fener Kapalı',
                        style: TextStyle(
                          color: state.isTorchOn ? Colors.amber : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hd, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${settings.qualityProfile.label} · ${settings.qualityProfile.height}p${settings.qualityProfile.fps}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Gecikme: ${state.latencyMs} ms',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => notifier.disconnect(),
            icon: const Icon(Icons.stop),
            label: const Text('Bağlantıyı Kes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    // Bekleniyor durumu (QR Kod göster)
    if (state.localIp != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrDisplay(
              ipAddress: state.localIp!,
              port: state.port,
              authToken: state.authToken,
            ),
            const SizedBox(height: 32),
            Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Bağlantı bekleniyor...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms, color: Colors.white54),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
