import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/logger.dart';
import '../../../receiver/presentation/receiver_screen.dart';
import '../../../sender/presentation/sender_screen.dart';

/// Gönderici veya Alıcı seçim widget'ı
class RoleSelector extends StatelessWidget {
  /// Sabit yapıcı
  const RoleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRoleCard(
          context: context,
          title: '📷 Kamera (Gönderici)',
          description: 'Bu cihazın kamerasını başka bir ekrana aktarın',
          icon: Icons.camera_alt,
          heroTag: 'sender_icon',
          color: Colors.blue,
          delayParams: 0,
          onTap: () {
            Logger.info('Gönderici modu seçildi');
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SenderScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          context: context,
          title: '🖥️ Ekran (Alıcı)',
          description: 'Başka bir cihazın kamerasını bu ekranda görün',
          icon: Icons.desktop_windows,
          heroTag: 'receiver_icon',
          color: Colors.green,
          delayParams: 200, // Staggered animation
          onTap: () {
            Logger.info('Alıcı modu seçildi');
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ReceiverScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required String heroTag,
    required Color color,
    required int delayParams,
    required VoidCallback onTap,
  }) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Hero(
                    tag: heroTag,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26), // 0.1 opacity
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: delayParams.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          delay: delayParams.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
