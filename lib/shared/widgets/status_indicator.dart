import 'package:flutter/material.dart';

/// Bağlantı durumunu gösteren widget
class StatusIndicator extends StatelessWidget {
  /// Mevcut durum mesajı
  final String status;

  /// Sabit yapıcı
  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }
}
