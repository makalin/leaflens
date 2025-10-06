import 'package:hive_flutter/hive_flutter.dart';
import 'package:leaflens/core/config/app_config.dart';
import 'package:leaflens/core/services/ml_service.dart';
import 'package:leaflens/core/services/storage_service.dart';
import 'package:leaflens/core/services/permission_service.dart';

class InitServices {
  static Future<void> initialize() async {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    await Hive.openBox(AppConfig.hiveBoxName);
    
    // Initialize storage service
    await StorageService.initialize();
    
    // Initialize permission service
    await PermissionService.initialize();
    
    // Initialize ML service (load models)
    await MLService.initialize();
  }
}