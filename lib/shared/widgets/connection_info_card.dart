import 'dart:async';
import 'package:flutter/material.dart';

import '../models/quality_profile.dart';

/// Bağlantı kurulduğunda 3 saniye görünüp kaybolan bilgi kartı.
class ConnectionInfoCard extends StatefulWidget {
  final String ipAddress;
  final QualityProfile qualityProfile;
  final int latencyMs;
  final VoidCallback onDismiss;

  const ConnectionInfoCard({
    super.key,
    required this.ipAddress,
    required this.qualityProfile,
    required this.latencyMs,
    required this.onDismiss,
  });

  @override
  State<ConnectionInfoCard> createState() => _ConnectionInfoCardState();
}

class _ConnectionInfoCardState extends State<ConnectionInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // 3 saniye sonra otomatik kapan
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Koyu arkaplan
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.green.withAlpha(100),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bağlantı kuruldu!',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const Icon(Icons.close, color: Colors.grey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.wifi,
                    'Bağlantı',
                    'Lokal Ağ (${widget.ipAddress})',
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.hd,
                    'Kalite',
                    '${widget.qualityProfile.label} (${widget.qualityProfile.height}p ${widget.qualityProfile.fps}fps)',
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.speed,
                    'Gecikme',
                    '~${widget.latencyMs}ms',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
