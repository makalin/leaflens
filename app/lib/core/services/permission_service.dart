import 'package:permission_handler/permission_handler.dart';
import 'package:leaflens/core/config/app_config.dart';

class PermissionService {
  static Future<void> initialize() async {
    // Request camera permission on app start if needed
    if (AppConfig.allowLocationAccess) {
      await requestLocationPermission();
    }
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'camera': await checkCameraPermission(),
      'location': await checkLocationPermission(),
      'storage': await checkStoragePermission(),
    };
  }

  static Future<bool> requestAllPermissions() async {
    final results = await [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ].request();

    return results.values.every((status) => status.isGranted);
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static Future<bool> isPermissionDeniedForever(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}