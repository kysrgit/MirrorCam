import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/quality_profile.dart';

part 'settings_provider.g.dart';

/// Ayarlar durum yönetimi
class SettingsState {
  final QualityProfile qualityProfile;
  final bool isMirrorEnabled;
  final double screenBrightness;
  final bool autoRotate;
  final ThemeMode themeMode;
  final bool hasSeenOnboarding;

  const SettingsState({
    this.qualityProfile = QualityProfile.ultra, // Varsayılanı Ultra yaptık
    this.isMirrorEnabled = true,
    this.screenBrightness = 1.0,
    this.autoRotate = true,
    this.themeMode = ThemeMode.dark,
    this.hasSeenOnboarding = false,
  });

  SettingsState copyWith({
    QualityProfile? qualityProfile,
    bool? isMirrorEnabled,
    double? screenBrightness,
    bool? autoRotate,
    ThemeMode? themeMode,
    bool? hasSeenOnboarding,
  }) {
    return SettingsState(
      qualityProfile: qualityProfile ?? this.qualityProfile,
      isMirrorEnabled: isMirrorEnabled ?? this.isMirrorEnabled,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      autoRotate: autoRotate ?? this.autoRotate,
      themeMode: themeMode ?? this.themeMode,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _initPrefs();
    return const SettingsState(); // Varsayılan değerler
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    final profileVal = _prefs?.getString('qualityProfile');
    final profile = profileVal != null
        ? QualityProfile.fromString(profileVal)
        : QualityProfile.ultra;

    final isMirrorEnabled = _prefs?.getBool('isMirrorEnabled') ?? true;
    final screenBrightness = _prefs?.getDouble('screenBrightness') ?? 1.0;
    final autoRotate = _prefs?.getBool('autoRotate') ?? true;

    final themeModeVal = _prefs?.getString('themeMode');
    final themeMode = themeModeVal == 'light'
        ? ThemeMode.light
        : themeModeVal == 'system'
        ? ThemeMode.system
        : ThemeMode.dark;

    final hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;

    state = SettingsState(
      qualityProfile: profile,
      isMirrorEnabled: isMirrorEnabled,
      screenBrightness: screenBrightness,
      autoRotate: autoRotate,
      themeMode: themeMode,
      hasSeenOnboarding: hasSeenOnboarding,
    );
  }

  void setQualityProfile(QualityProfile profile) {
    state = state.copyWith(qualityProfile: profile);
    _prefs?.setString('qualityProfile', profile.name);
  }

  void setIsMirrorEnabled(bool isEnabled) {
    state = state.copyWith(isMirrorEnabled: isEnabled);
    _prefs?.setBool('isMirrorEnabled', isEnabled);
  }

  void setScreenBrightness(double brightness) {
    state = state.copyWith(screenBrightness: brightness);
    _prefs?.setDouble('screenBrightness', brightness);
  }

  void setAutoRotate(bool autoRotate) {
    state = state.copyWith(autoRotate: autoRotate);
    _prefs?.setBool('autoRotate', autoRotate);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setString('themeMode', mode.name);
  }

  void setHasSeenOnboarding(bool hasSeen) {
    state = state.copyWith(hasSeenOnboarding: hasSeen);
    _prefs?.setBool('hasSeenOnboarding', hasSeen);
  }
}
