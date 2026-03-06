// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/quality_profile.dart';
import '../../home/presentation/widgets/onboarding_sheet.dart';
import '../providers/settings_provider.dart';

/// Ayarların hangi modda açıldığını belirten tür
enum SettingsContext { home, sender, receiver }

/// Ayarlar ekranı
class SettingsScreen extends ConsumerWidget {
  final SettingsContext settingsContext;

  /// Sabit yapıcı
  const SettingsScreen({super.key, required this.settingsContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (settingsContext == SettingsContext.home ||
              settingsContext == SettingsContext.sender) ...[
            _buildSectionHeader(
              context,
              'Gönderici Ayarları',
              Icons.camera_alt,
            ),
            const SizedBox(height: 16),
            _buildSenderSettings(context, state, notifier),
            const Divider(height: 32),
          ],
          if (settingsContext == SettingsContext.home ||
              settingsContext == SettingsContext.receiver) ...[
            _buildSectionHeader(context, 'Alıcı Ayarları', Icons.tv),
            const SizedBox(height: 16),
            _buildReceiverSettings(context, state, notifier),
            const Divider(height: 32),
          ],
          _buildSectionHeader(context, 'Ortak Ayarlar', Icons.settings),
          const SizedBox(height: 16),
          _buildCommonSettings(context, state, notifier),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSenderSettings(
    BuildContext context,
    SettingsState state,
    SettingsNotifier notifier,
  ) {
    String getTooltipForProfile(QualityProfile profile) {
      switch (profile) {
        case QualityProfile.balanced:
          return 'Düşük bant genişliği veya eski cihazlar için. 720p 30fps.';
        case QualityProfile.high:
          return 'Çoğu kullanım için ideal. 1080p 30fps.';
        case QualityProfile.ultra:
          return 'En akıcı deneyim. 1080p 60fps. WiFi 6 önerilir.';
        case QualityProfile.maxClarity:
          return 'En yüksek çözünürlük. 1440p 30fps. Güçlü cihaz gerektirir.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Görüntü Kalitesi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Tooltip(
              message:
                  'Ağ hızınıza ve cihaz performansına göre kaliteyi seçin.',
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...QualityProfile.values.map(
          (profile) => RadioListTile<QualityProfile>(
            title: Row(
              children: [
                Text(profile.label),
                if (profile == QualityProfile.ultra) const Text(' ⭐'),
                const Spacer(),
                Tooltip(
                  message: getTooltipForProfile(profile),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${profile.width}x${profile.height} · ${profile.fps}fps · '
              '${profile.maxBitrate ~/ 1000000} Mbps',
            ),
            value: profile,
            groupValue: state.qualityProfile,
            onChanged: (value) {
              if (value != null) notifier.setQualityProfile(value);
            },
            contentPadding: EdgeInsets.zero,
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
                    'WiFi 6 router\'ınız varsa\n"Ultra" profili önerilir.',
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

  Widget _buildReceiverSettings(
    BuildContext context,
    SettingsState state,
    SettingsNotifier notifier,
  ) {
    return Column(
      children: [
        SwitchListTile(
          title: Row(
            children: [
              const Text('Ayna Modu'),
              const Spacer(),
              Tooltip(
                message:
                    'Görüntüyü yatay çevirir. Ayna gibi kullanmak için açın.',
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          value: state.isMirrorEnabled,
          onChanged: notifier.setIsMirrorEnabled,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.brightness_6, size: 20),
            const SizedBox(width: 16),
            const Text('Ekran Parlaklığı'),
            Expanded(
              child: Slider(
                value: state.screenBrightness,
                min: 0.1,
                max: 1.0,
                onChanged: notifier.setScreenBrightness,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Otomatik Ekran Dönüşü'),
          value: state.autoRotate,
          onChanged: notifier.setAutoRotate,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildCommonSettings(
    BuildContext context,
    SettingsState state,
    SettingsNotifier notifier,
  ) {
    return Column(
      children: [
        ListTile(
          title: const Text('Tema'),
          trailing: DropdownButton<ThemeMode>(
            value: state.themeMode,
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('Sistem')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Açık')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Koyu')),
            ],
            onChanged: (mode) {
              if (mode != null) notifier.setThemeMode(mode);
            },
            underline: const SizedBox(),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          title: const Text('Kullanım Rehberi'),
          leading: const Icon(Icons.help_outline),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            OnboardingSheet.show(context);
          },
        ),
        ListTile(
          title: const Text('Hakkında'),
          leading: const Icon(Icons.info_outline),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'MirrorCam',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 MirrorCam',
            );
          },
        ),
      ],
    );
  }
}
