import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../shared/widgets/connection_info_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/receiver_provider.dart';
import 'widgets/mirror_controls.dart';
import 'widgets/qr_scanner.dart';

/// Alıcı ekranı: QR tarama → tam ekran video gösterimi.
/// Tek dokunuş: overlay kontrolleri göster/gizle
/// Çift dokunuş: mirror toggle
/// Pinch-to-zoom: 1x-5x yakınlaştırma
class ReceiverScreen extends ConsumerStatefulWidget {
  /// Sabit yapıcı
  const ReceiverScreen({super.key});

  @override
  ConsumerState<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends ConsumerState<ReceiverScreen>
    with WidgetsBindingObserver {
  bool _showControls = false;
  bool _showConnectionInfo = false;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // System UI'yı geri getir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uygulama arka plana alındı. Video akışı duraklatılabilir.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Status bar ve nav bar'ı gizler (tam ekran immersive)
  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    // Bağlantı durumu değiştiğinde bağlantı bilgi kartını göster
    ref.listen<ReceiverState>(receiverNotifierProvider, (previous, next) {
      if (previous?.status != ReceiverConnectionStatus.connected &&
          next.status == ReceiverConnectionStatus.connected) {
        setState(() {
          _showConnectionInfo = true;
        });
      }
    });

    final receiverState = ref.watch(receiverNotifierProvider);
    final notifier = ref.read(receiverNotifierProvider.notifier);

    // Bağlı durumda değilse QR tarama ekranı
    if (receiverState.status == ReceiverConnectionStatus.idle ||
        receiverState.status == ReceiverConnectionStatus.error) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ekran (Alıcı)'),
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        body: SafeArea(child: _buildScannerOrError(receiverState, notifier)),
      );
    }

    // Bağlanıyor durumu
    if (receiverState.status == ReceiverConnectionStatus.connecting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ekran (Alıcı)')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_find, size: 64, color: Colors.blueAccent)
                  .animate(onPlay: (controller) => controller.repeat())
                  .scaleXY(
                    begin: 0.8,
                    end: 1.2,
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.2,
                    end: 0.8,
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              const Text('Gönderici cihaza bağlanılıyor...'),
            ],
          ),
        ),
      );
    }

    // Tam ekran video modu
    _enterFullscreen();
    return _buildFullscreenVideo(receiverState, notifier);
  }

  /// QR tarayıcı veya hata ekranı
  Widget _buildScannerOrError(ReceiverState state, ReceiverNotifier notifier) {
    if (state.status == ReceiverConnectionStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.errorMessage ?? 'Bilinmeyen hata',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Idle'a dön ve tekrar QR tarayıcı göster
                notifier.disconnect();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return QrScanner(
      onScanned: (ip, port) {
        notifier.connectTo(ip, port);
      },
    );
  }

  /// Tam ekran video görünümü (overlay kontrolleri ile)
  Widget _buildFullscreenVideo(ReceiverState state, ReceiverNotifier notifier) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tek dokunuş: Kontrolleri göster/gizle
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        // Çift dokunuş: Mirror toggle
        onDoubleTap: () {
          notifier.toggleMirror();
        },
        // Pinch-to-zoom gesture başlangıcı
        onScaleStart: (details) {
          _baseScale = state.zoomLevel;
        },
        // Pinch-to-zoom gesture güncellemesi
        onScaleUpdate: (details) {
          notifier.setZoom(_baseScale * details.scale);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video katmanı
            if (state.remoteRenderer != null)
              Transform(
                alignment: Alignment.center,
                transform: state.isMirrored
                    ? Matrix4.diagonal3Values(
                        -state.zoomLevel,
                        state.zoomLevel,
                        1.0,
                      )
                    : Matrix4.diagonal3Values(
                        state.zoomLevel,
                        state.zoomLevel,
                        1.0,
                      ),
                child: RTCVideoView(
                  state.remoteRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: false, // Transform ile yönetiyoruz
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Video akışı bekleniyor...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

            // Yeniden bağlanma overlay'i
            if (state.status == ReceiverConnectionStatus.reconnecting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      SizedBox(height: 16),
                      Text(
                        'Bağlantı yeniden kuruluyor...',
                        style: TextStyle(color: Colors.amber, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Kontrol paneli overlay'i
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: MirrorControls(
                  isMirrored: state.isMirrored,
                  zoomLevel: state.zoomLevel,
                  latencyMs: state.latencyMs,
                  connectionStatus: _connectionStatusText(state.status),
                  isTorchOn: state.isTorchOn,
                  isTorchAvailable: state.isTorchAvailable,
                  isTorchLoading: state.isTorchLoading,
                  onToggleMirror: () => notifier.toggleMirror(),
                  onZoomChanged: (zoom) => notifier.setZoom(zoom),
                  onToggleTorch: () => notifier.toggleTorch(),
                  onDisconnect: () {
                    notifier.disconnect();
                    // System UI'yı geri getir
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                  },
                ),
              ),
            ),

            // Bağlantı Bilgi Kartı (Bağlandığında kısa süre görünür)
            if (_showConnectionInfo)
              ConnectionInfoCard(
                ipAddress: 'WiFi Bağlantısı', // Opsiyonel bilgi
                qualityProfile: ref
                    .watch(settingsNotifierProvider)
                    .qualityProfile,
                latencyMs: state.latencyMs,
                onDismiss: () {
                  if (mounted) {
                    setState(() {
                      _showConnectionInfo = false;
                    });
                  }
                },
              ),

            // Geri butonu (her zaman görünür, sol üst)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: IconButton(
                    tooltip: 'Geri',
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      notifier.disconnect();
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bağlantı durumunu kullanıcıya gösterilecek metne çevirir
  String _connectionStatusText(ReceiverConnectionStatus status) {
    switch (status) {
      case ReceiverConnectionStatus.connected:
        return 'Bağlı';
      case ReceiverConnectionStatus.connecting:
        return 'Bağlanıyor...';
      case ReceiverConnectionStatus.reconnecting:
        return 'Yeniden bağlanıyor...';
      case ReceiverConnectionStatus.failed:
        return 'Bağlantı başarısız';
      case ReceiverConnectionStatus.error:
        return 'Hata';
      case ReceiverConnectionStatus.idle:
        return 'Bekliyor';
    }
  }
}
