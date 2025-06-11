import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/constants.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Video Quality Settings
  String get videoQuality => _prefs.getString(AppConstants.keyVideoQuality) ?? AppConstants.defaultQuality;
  Future<void> setVideoQuality(String quality) async {
    await _prefs.setString(AppConstants.keyVideoQuality, quality);
  }

  // Language Settings
  String get language => _prefs.getString(AppConstants.keyLanguage) ?? AppConstants.defaultLanguage;
  Future<void> setLanguage(String language) async {
    await _prefs.setString(AppConstants.keyLanguage, language);
  }

  // Download Path Settings
  String get downloadPath => _prefs.getString(AppConstants.keyDownloadPath) ?? AppConstants.defaultDownloadPath;
  Future<void> setDownloadPath(String path) async {
    await _prefs.setString(AppConstants.keyDownloadPath, path);
  }

  // Auto Download Settings
  bool get autoDownload => _prefs.getBool(AppConstants.keyAutoDownload) ?? true;
  Future<void> setAutoDownload(bool enabled) async {
    await _prefs.setBool(AppConstants.keyAutoDownload, enabled);
  }

  // WiFi Only Settings
  bool get wifiOnly => _prefs.getBool(AppConstants.keyWifiOnly) ?? true;
  Future<void> setWifiOnly(bool enabled) async {
    await _prefs.setBool(AppConstants.keyWifiOnly, enabled);
  }

  // Check Interval Settings
  Duration get checkInterval {
    final minutes = _prefs.getInt(AppConstants.keyCheckInterval) ?? AppConstants.defaultCheckInterval.inMinutes;
    return Duration(minutes: minutes);
  }
  Future<void> setCheckInterval(Duration interval) async {
    await _prefs.setInt(AppConstants.keyCheckInterval, interval.inMinutes);
  }

  // Theme Settings
  String get theme => _prefs.getString(AppConstants.keyTheme) ?? 'system';
  Future<void> setTheme(String theme) async {
    await _prefs.setString(AppConstants.keyTheme, theme);
  }

  // Notification Settings
  bool get notificationsEnabled => _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  bool get downloadNotifications => _prefs.getBool(AppConstants.keyDownloadNotifications) ?? true;
  Future<void> setDownloadNotifications(bool enabled) async {
    await _prefs.setBool(AppConstants.keyDownloadNotifications, enabled);
  }

  bool get episodeNotifications => _prefs.getBool(AppConstants.keyEpisodeNotifications) ?? true;
  Future<void> setEpisodeNotifications(bool enabled) async {
    await _prefs.setBool(AppConstants.keyEpisodeNotifications, enabled);
  }

  // Storage Management
  Future<String> getDefaultDownloadPath() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return '${directory?.path}/Senpie';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/Senpie';
    }
  }

  Future<String?> selectDownloadPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await setDownloadPath(result);
        return result;
      }
      return null;
    } catch (e) {
      print('Failed to select download path: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final downloadPath = this.downloadPath;
      final directory = Directory(downloadPath);
      
      if (!await directory.exists()) {
        return {
          'totalSize': 0,
          'fileCount': 0,
          'folderCount': 0,
          'path': downloadPath,
        };
      }

      int totalSize = 0;
      int fileCount = 0;
      int folderCount = 0;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileCount++;
        } else if (entity is Directory) {
          folderCount++;
        }
      }

      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'folderCount': folderCount,
        'path': downloadPath,
      };
    } catch (e) {
      print('Failed to get storage info: $e');
      return {
        'totalSize': 0,
        'fileCount': 0,
        'folderCount': 0,
        'path': downloadPath,
      };
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> clearCache() async {
    try {
      // Clear temporary files
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }

      // Clear app cache
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (e) {
      print('Failed to clear cache: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'videoQuality': videoQuality,
      'language': language,
      'downloadPath': downloadPath,
      'autoDownload': autoDownload,
      'wifiOnly': wifiOnly,
      'checkInterval': checkInterval.inMinutes,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'downloadNotifications': downloadNotifications,
      'episodeNotifications': episodeNotifications,
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('videoQuality')) {
        await setVideoQuality(settings['videoQuality']);
      }
      if (settings.containsKey('language')) {
        await setLanguage(settings['language']);
      }
      if (settings.containsKey('downloadPath')) {
        await setDownloadPath(settings['downloadPath']);
      }
      if (settings.containsKey('autoDownload')) {
        await setAutoDownload(settings['autoDownload']);
      }
      if (settings.containsKey('wifiOnly')) {
        await setWifiOnly(settings['wifiOnly']);
      }
      if (settings.containsKey('checkInterval')) {
        await setCheckInterval(Duration(minutes: settings['checkInterval']));
      }
      if (settings.containsKey('theme')) {
        await setTheme(settings['theme']);
      }
      if (settings.containsKey('notificationsEnabled')) {
        await setNotificationsEnabled(settings['notificationsEnabled']);
      }
      if (settings.containsKey('downloadNotifications')) {
        await setDownloadNotifications(settings['downloadNotifications']);
      }
      if (settings.containsKey('episodeNotifications')) {
        await setEpisodeNotifications(settings['episodeNotifications']);
      }
    } catch (e) {
      print('Failed to import settings: $e');
      rethrow;
    }
  }

  Future<void> resetToDefaults() async {
    await setVideoQuality(AppConstants.defaultQuality);
    await setLanguage(AppConstants.defaultLanguage);
    await setDownloadPath(await getDefaultDownloadPath());
    await setAutoDownload(true);
    await setWifiOnly(true);
    await setCheckInterval(AppConstants.defaultCheckInterval);
    await setTheme('system');
    await setNotificationsEnabled(true);
    await setDownloadNotifications(true);
    await setEpisodeNotifications(true);
  }

  // Get all settings as a map for debugging
  Map<String, dynamic> getAllSettings() {
    return {
      'videoQuality': videoQuality,
      'language': language,
      'downloadPath': downloadPath,
      'autoDownload': autoDownload,
      'wifiOnly': wifiOnly,
      'checkInterval': checkInterval.inMinutes,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'downloadNotifications': downloadNotifications,
      'episodeNotifications': episodeNotifications,
    };
  }
}

