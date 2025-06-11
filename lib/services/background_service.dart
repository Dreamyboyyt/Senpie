import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';
import 'anime_tracking_service.dart';
import 'download_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _initializeNotifications();
    await _initializeWorkManager();
    await _scheduleEpisodeCheckTask();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Download notification channel
    const downloadChannel = AndroidNotificationChannel(
      AppConstants.downloadChannelId,
      'Downloads',
      description: 'Notifications for download progress and completion',
      importance: Importance.low,
      playSound: false,
    );

    // Episode notification channel
    const episodeChannel = AndroidNotificationChannel(
      AppConstants.episodeChannelId,
      'New Episodes',
      description: 'Notifications for new episode releases',
      importance: Importance.high,
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(downloadChannel);
      await androidPlugin.createNotificationChannel(episodeChannel);
    }
  }

  Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> _scheduleEpisodeCheckTask() async {
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt(AppConstants.keyCheckInterval) ?? 60;

    await Workmanager().registerPeriodicTask(
      AppConstants.episodeCheckTaskName,
      AppConstants.episodeCheckTaskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> updateCheckInterval(Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCheckInterval, interval.inMinutes);
    
    // Cancel existing task and reschedule
    await Workmanager().cancelByUniqueName(AppConstants.episodeCheckTaskName);
    await _scheduleEpisodeCheckTask();
  }

  Future<void> showNewEpisodeNotification({
    required String animeTitle,
    required int episodeNumber,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.episodeChannelId,
      'New Episodes',
      channelDescription: 'Notifications for new episode releases',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      episodeNumber,
      'New Episode Available!',
      '$animeTitle - Episode $episodeNumber is now available',
      notificationDetails,
    );
  }

  Future<void> showDownloadCompleteNotification({
    required String animeTitle,
    required int episodeNumber,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.downloadChannelId,
      'Downloads',
      channelDescription: 'Notifications for download completion',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1000 + episodeNumber,
      'Download Complete',
      '$animeTitle - Episode $episodeNumber has been downloaded',
      notificationDetails,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> stopBackgroundTasks() async {
    await Workmanager().cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case AppConstants.episodeCheckTaskName:
          await _checkForNewEpisodes();
          break;
        default:
          print('Unknown background task: $task');
      }
      return Future.value(true);
    } catch (e) {
      print('Background task failed: $e');
      return Future.value(false);
    }
  });
}

Future<void> _checkForNewEpisodes() async {
  try {
    final trackingService = AnimeTrackingService();
    final downloadService = DownloadService();
    final backgroundService = BackgroundService();
    
    // Initialize services
    await trackingService.initialize();
    await downloadService.initialize();
    
    // Get current tracked anime
    final trackedAnime = trackingService.trackedAnime;
    
    for (final anime in trackedAnime) {
      try {
        final oldEpisodeCount = anime.episodes.length;
        
        // Check for new episodes
        await trackingService.updateAnimeEpisodes(anime.id);
        
        // Get updated anime data
        final updatedAnime = trackingService.trackedAnime
            .firstWhere((a) => a.id == anime.id);
        
        final newEpisodeCount = updatedAnime.episodes.length;
        
        // If new episodes found
        if (newEpisodeCount > oldEpisodeCount) {
          final newEpisodes = updatedAnime.episodes
              .where((ep) => ep.episodeNumber > oldEpisodeCount)
              .toList();
          
          for (final episode in newEpisodes) {
            // Show notification
            await backgroundService.showNewEpisodeNotification(
              animeTitle: anime.title,
              episodeNumber: episode.episodeNumber,
            );
            
            // Auto-download if enabled
            if (anime.autoDownload) {
              final prefs = await SharedPreferences.getInstance();
              final autoDownload = prefs.getBool(AppConstants.keyAutoDownload) ?? false;
              final wifiOnly = prefs.getBool(AppConstants.keyWifiOnly) ?? true;
              
              if (autoDownload) {
                // Check WiFi requirement
                bool canDownload = true;
                if (wifiOnly) {
                  // TODO: Check if connected to WiFi
                  // For now, assume we can download
                }
                
                if (canDownload) {
                  await downloadService.downloadEpisode(
                    animeId: anime.id,
                    episodeNumber: episode.episodeNumber,
                    animeTitle: anime.title,
                  );
                }
              }
            }
          }
        }
        
        // Add delay between anime checks
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('Failed to check episodes for ${anime.title}: $e');
        // Continue with next anime
      }
    }
  } catch (e) {
    print('Episode check task failed: $e');
  }
}

