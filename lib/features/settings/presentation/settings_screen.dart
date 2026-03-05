import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/latency_mode.dart';
import '../../../shared/models/quality_profile.dart';
import '../providers/settings_provider.dart';

/// Ayarlar ekranı
class SettingsScreen extends ConsumerWidget {
  /// Sabit yapıcı
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildQualitySection(context, state, notifier),
          const Divider(height: 32),
          _buildLatencySection(context, state, notifier),
        ],
      ),
    );
  }

  Widget _buildQualitySection(
    BuildContext context,
    SettingsState state,
    SettingsNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görüntü Kalitesi',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...QualityProfile.values.map(
          (profile) => RadioListTile<QualityProfile>(
            title: Text(profile.label),
            subtitle: Text(
              '${profile.width}x${profile.height} · ${profile.fps}fps · '
              '${profile.maxBitrate ~/ 1000000} Mbps',
            ),
            value: profile,
            groupValue: state.qualityProfile,
            onChanged: (value) {
              if (value != null) {
                notifier.setQualityProfile(value);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          color: Color(0xFF1A3A2A),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.wifi, color: Colors.greenAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WiFi 6 router kullanıyorsanız "Ultra" profili önerilir.',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatencySection(
    BuildContext context,
    SettingsState state,
    SettingsNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gecikme Modu',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...LatencyMode.values.map(
          (mode) => RadioListTile<LatencyMode>(
            title: Text(mode.label),
            value: mode,
            groupValue: state.latencyMode,
            onChanged: (value) {
              if (value != null) {
                notifier.setLatencyMode(value);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ayna kullanımı için cihazlar arası doğrudan ağ veya hotspot kullanılması önerilir.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
