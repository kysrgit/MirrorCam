import 'package:flutter/material.dart';

/// Receiver ekranındaki ayna kontrol paneli widget'ları.
/// Overlay olarak gösterilen yarı saydam kontrol arayüzü.
class MirrorControls extends StatelessWidget {
  /// Ayna (mirror) durumu
  final bool isMirrored;

  /// Mevcut zoom seviyesi (1.0 - 5.0)
  final double zoomLevel;

  /// Gecikme göstergesi (ms)
  final int latencyMs;

  /// Torch (Fener) acik mi?
  final bool isTorchOn;

  /// Torch (Fener) mevcut mu?
  final bool isTorchAvailable;

  /// Torch islemde mi? (loading)
  final bool isTorchLoading;

  /// Bağlantı durumu metni
  final String connectionStatus;

  /// Mirror toggle callback
  final VoidCallback onToggleMirror;

  /// Zoom değişim callback
  final ValueChanged<double> onZoomChanged;

  /// Fener ac/kapat toggle callback
  final VoidCallback onToggleTorch;

  /// Bağlantıyı kes callback
  final VoidCallback onDisconnect;

  /// Sabit yapıcı
  const MirrorControls({
    super.key,
    required this.isMirrored,
    required this.zoomLevel,
    required this.latencyMs,
    required this.connectionStatus,
    required this.isTorchOn,
    required this.isTorchAvailable,
    required this.isTorchLoading,
    required this.onToggleMirror,
    required this.onZoomChanged,
    required this.onToggleTorch,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst bar: Bağlantı durumu
          _buildTopBar(context),

          // Alt bar: Kontroller
          _buildBottomControls(context),
        ],
      ),
    );
  }

  /// Üst bilgi çubuğu (bağlantı durumu + gecikme)
  Widget _buildTopBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153), // 0.6 opacity
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connectionStatus,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (latencyMs > 0) ...[
            const SizedBox(width: 12),
            Text(
              '${latencyMs}ms',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Alt kontrol çubuğu
  Widget _buildBottomControls(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom slider
          Row(
            children: [
              const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
              Expanded(
                child: Slider(
                  value: zoomLevel,
                  min: 1.0,
                  max: 5.0,
                  divisions: 40,
                  label: '${zoomLevel.toStringAsFixed(1)}x',
                  onChanged: onZoomChanged,
                ),
              ),
              const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              Text(
                '${zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Butonlar satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mirror toggle
              _ControlButton(
                icon: Icons.flip,
                label: 'Ayna',
                isActive: isMirrored,
                onTap: onToggleMirror,
              ),

              // Torch toggle (Fener)
              if (isTorchAvailable) ...[
                _ControlButton(
                  icon: isTorchLoading
                      ? Icons.hourglass_empty
                      : (isTorchOn
                            ? Icons.flashlight_on
                            : Icons.flashlight_off),
                  label: 'Fener',
                  isActive: isTorchOn && !isTorchLoading,
                  onTap: isTorchLoading ? () {} : onToggleTorch,
                ),
              ],

              // Bağlantıyı kes
              _ControlButton(
                icon: Icons.call_end,
                label: 'Kapat',
                isActive: false,
                isDestructive: true,
                onTap: onDisconnect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tekil kontrol butonu widget'ı
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;

    if (isDestructive) {
      bgColor = Colors.red.withAlpha(51);
      fgColor = Colors.redAccent;
    } else if (isActive) {
      bgColor = Colors.deepPurple.withAlpha(77);
      fgColor = Colors.deepPurpleAccent;
    } else {
      bgColor = Colors.white.withAlpha(26);
      fgColor = Colors.white70;
    }

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: fgColor, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: fgColor, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
