import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leaflens/core/config/app_config.dart';
import 'package:leaflens/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:leaflens/features/history/domain/entities/diagnosis_history.dart';

class StorageService {
  static late Box _box;
  static const String _diagnosisHistoryKey = 'diagnosis_history';
  static const String _settingsKey = 'settings';
  static const String _userPreferencesKey = 'user_preferences';

  static Future<void> initialize() async {
    _box = Hive.box(AppConfig.hiveBoxName);
  }

  // Diagnosis History
  static Future<void> saveDiagnosisResult(DiagnosisResult result) async {
    final history = getDiagnosisHistory();
    final newHistoryItem = DiagnosisHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      result: result,
      timestamp: DateTime.now(),
    );
    
    history.add(newHistoryItem);
    
    // Keep only the most recent items
    if (history.length > AppConfig.maxHistoryItems) {
      history.removeRange(0, history.length - AppConfig.maxHistoryItems);
    }
    
    await _box.put(_diagnosisHistoryKey, history.map((item) => item.toJson()).toList());
  }

  static List<DiagnosisHistoryItem> getDiagnosisHistory() {
    final data = _box.get(_diagnosisHistoryKey, defaultValue: <Map<String, dynamic>>[]);
    return data
        .map<DiagnosisHistoryItem>((json) => DiagnosisHistoryItem.fromJson(json))
        .toList();
  }

  static Future<void> clearDiagnosisHistory() async {
    await _box.delete(_diagnosisHistoryKey);
  }

  static Future<void> deleteDiagnosisItem(String id) async {
    final history = getDiagnosisHistory();
    history.removeWhere((item) => item.id == id);
    await _box.put(_diagnosisHistoryKey, history.map((item) => item.toJson()).toList());
  }

  // Settings
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _box.put(_settingsKey, settings);
  }

  static Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(_box.get(_settingsKey, defaultValue: <String, dynamic>{}));
  }

  static T getSetting<T>(String key, T defaultValue) {
    final settings = getSettings();
    return settings[key] ?? defaultValue;
  }

  static Future<void> setSetting<T>(String key, T value) async {
    final settings = getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // User Preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await _box.put(_userPreferencesKey, preferences);
  }

  static Map<String, dynamic> getUserPreferences() {
    return Map<String, dynamic>.from(_box.get(_userPreferencesKey, defaultValue: <String, dynamic>{}));
  }

  static T getPreference<T>(String key, T defaultValue) {
    final preferences = getUserPreferences();
    return preferences[key] ?? defaultValue;
  }

  static Future<void> setPreference<T>(String key, T value) async {
    final preferences = getUserPreferences();
    preferences[key] = value;
    await saveUserPreferences(preferences);
  }

  // Cache Management
  static Future<void> clearCache() async {
    await _box.clear();
  }

  static int getCacheSize() {
    return _box.length;
  }

  static Future<void> clearOldCache() async {
    // This is a simplified implementation
    // In a real app, you'd want more sophisticated cache management
    final history = getDiagnosisHistory();
    if (history.length > AppConfig.maxHistoryItems) {
      final recentHistory = history.skip(history.length - AppConfig.maxHistoryItems).toList();
      await _box.put(_diagnosisHistoryKey, recentHistory.map((item) => item.toJson()).toList());
    }
  }

  // Export/Import
  static Map<String, dynamic> exportData() {
    return {
      'diagnosis_history': getDiagnosisHistory().map((item) => item.toJson()).toList(),
      'settings': getSettings(),
      'user_preferences': getUserPreferences(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    if (data.containsKey('diagnosis_history')) {
      final historyData = List<Map<String, dynamic>>.from(data['diagnosis_history']);
      await _box.put(_diagnosisHistoryKey, historyData);
    }
    
    if (data.containsKey('settings')) {
      await _box.put(_settingsKey, data['settings']);
    }
    
    if (data.containsKey('user_preferences')) {
      await _box.put(_userPreferencesKey, data['user_preferences']);
    }
  }
}