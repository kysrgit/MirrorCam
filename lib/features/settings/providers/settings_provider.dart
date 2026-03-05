import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/latency_mode.dart';
import '../../../shared/models/quality_profile.dart';

part 'settings_provider.g.dart';

/// Ayarlar durum yönetimi
class SettingsState {
  final QualityProfile qualityProfile;
  final LatencyMode latencyMode;

  const SettingsState({
    this.qualityProfile = QualityProfile.ultra, // Varsayılanı Ultra yaptık
    this.latencyMode = LatencyMode.ultraLow,
  });

  SettingsState copyWith({
    QualityProfile? qualityProfile,
    LatencyMode? latencyMode,
  }) {
    return SettingsState(
      qualityProfile: qualityProfile ?? this.qualityProfile,
      latencyMode: latencyMode ?? this.latencyMode,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _initPrefs();
    return const SettingsState(); // Varsayılan değerler (ultra, ultraLow)
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    final profileVal = _prefs?.getString('qualityProfile');
    final profile = profileVal != null
        ? QualityProfile.fromString(profileVal)
        : QualityProfile.ultra;

    final latVal = _prefs?.getString('latencyMode');
    final lat = latVal != null
        ? LatencyMode.fromString(latVal)
        : LatencyMode.ultraLow;

    state = SettingsState(qualityProfile: profile, latencyMode: lat);
  }

  void setQualityProfile(QualityProfile profile) {
    state = state.copyWith(qualityProfile: profile);
    _prefs?.setString('qualityProfile', profile.name);
  }

  void setLatencyMode(LatencyMode mode) {
    state = state.copyWith(latencyMode: mode);
    _prefs?.setString('latencyMode', mode.name);
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

    final resValue = _prefs?.getString('resolution');
    final res = resValue != null
        ? VideoResolution.fromString(resValue)
        : VideoResolution.r1080p;

    final fps = _prefs?.getInt('fps') ?? 30;
    final bitrate = _prefs?.getInt('bitrate') ?? 4;

    state = SettingsState(resolution: res, fps: fps, bitrateMbps: bitrate);
  }

  void setResolution(VideoResolution res) {
    state = state.copyWith(resolution: res);
    _prefs?.setString('resolution', res.name);
  }

  void setFps(int fps) {
    state = state.copyWith(fps: fps);
    _prefs?.setInt('fps', fps);
  }

  void setBitrate(int bitrateMbps) {
    state = state.copyWith(bitrateMbps: bitrateMbps);
    _prefs?.setInt('bitrate', bitrateMbps);
  }
}
