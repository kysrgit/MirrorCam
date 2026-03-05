import 'package:permission_handler/permission_handler.dart';

import 'logger.dart';

/// Permission result enum providing more detail than a boolean
enum PermissionResult { granted, denied, permanentlyDenied }

/// Utility class for handling device permissions.
class PermissionUtils {
  /// Requests necessary permissions for the Sender (Camera) mode.
  /// Note: Only requests camera, NOT microphone per app requirements.
  static Future<PermissionResult> requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      if (status.isGranted) return PermissionResult.granted;

      status = await Permission.camera.request();

      if (status.isGranted) {
        return PermissionResult.granted;
      } else if (status.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
    } catch (e, st) {
      Logger.error('Failed to request camera permission', e, st);
      return PermissionResult.denied;
    }
  }

  /// Opens app settings for user to manually grant permissions
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Requests permissions for local network/discovery.
  /// Sometimes location is needed on older Android versions for WiFi state.
  static Future<bool> requestNetworkPermissions() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    } catch (e, st) {
      Logger.error('Failed to request network permission', e, st);
      return false;
    }
  }
}
