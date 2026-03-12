/// Core application constants.
class AppConstants {
  /// Local WebSocket server port for signaling
  static const int signalingPort = 8765;

  /// Application name used across the app
  static const String appName = 'MirrorCam';

  /// Default timeout values
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 15);
}
