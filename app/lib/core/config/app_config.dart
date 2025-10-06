import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'LeafLens';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.leaflens.com/v1',
  );
  
  // Privacy Modes
  static const String privacyMode = String.fromEnvironment(
    'PRIVACY_MODE',
    defaultValue: 'offline',
  );
  
  // Region Configuration
  static const String regionCode = String.fromEnvironment(
    'REGION_CODE',
    defaultValue: 'US',
  );
  
  // Model Configuration
  static const String modelVersion = String.fromEnvironment(
    'MODEL_VERSION',
    defaultValue: '1.0.0',
  );
  
  // Debug Configuration
  static const bool enableDebugLogs = kDebugMode;
  static const bool enableTelemetry = String.fromEnvironment(
    'ENABLE_TELEMETRY',
    defaultValue: 'false',
  ) == 'true';
  
  // Camera Configuration
  static const int maxImageSize = 1024;
  static const int imageQuality = 85;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  
  // ML Configuration
  static const int inputImageSize = 224;
  static const int maxPredictions = 5;
  static const double confidenceThreshold = 0.3;
  
  // Storage Configuration
  static const String hiveBoxName = 'leaflens_storage';
  static const int maxCacheSize = 100; // MB
  static const int maxHistoryItems = 1000;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Privacy Settings
  static const bool allowCloudSync = privacyMode != 'offline';
  static const bool allowTelemetry = enableTelemetry && privacyMode != 'offline';
  static const bool allowLocationAccess = privacyMode != 'offline';
}