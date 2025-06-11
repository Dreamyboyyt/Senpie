import 'dart:async';
import 'dart:convert'; // <<< ADD THIS IMPORT
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart' as fd; // Use prefix
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/anime_metadata.dart';
import '../models/download_task.dart';
import '../utils/constants.dart';
import 'anime_tracking_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final StreamController<List<DownloadTask>> _downloadTasksController =
      StreamController<List<DownloadTask>>.broadcast();

  final List<DownloadTask> _downloadTasks = [];
  final AnimeTrackingService _trackingService = AnimeTrackingService();

  Stream<List<DownloadTask>> get downloadTasksStream =>
      _downloadTasksController.stream;
  List<DownloadTask> get downloadTasks => List.unmodifiable(_downloadTasks);

  Future<void> initialize() async {
    await fd.FlutterDownloader.initialize(debug: true); // <<< FIX: Use prefix
    await _loadDownloadTasks();
    _setupDownloadCallback();
  }

  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final storagePermission = await Permission.storage.request();
      final notificationPermission = await Permission.notification.request();

      return storagePermission.isGranted && notificationPermission.isGranted;
    }
    return true;
  }

  Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    String downloadPath = prefs.getString(AppConstants.keyDownloadPath) ?? '';

    if (downloadPath.isEmpty) {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        downloadPath = '${directory?.path}/Senpie';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        downloadPath = '${directory.path}/Senpie';
      }

      final dir = Directory(downloadPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await prefs.setString(AppConstants.keyDownloadPath, downloadPath);
    }

    return downloadPath;
  }

  Future<void> downloadEpisode({
    required String animeId,
    required int episodeNumber,
    required String animeTitle,
    String quality = '720p',
  }) async {
    try {
      if (!await checkPermissions()) {
        throw Exception('Storage permission required for downloads');
      }

      final existingTask = _downloadTasks.firstWhere(
        (task) => task.animeId == animeId && task.episodeNumber == episodeNumber,
        orElse: () => DownloadTask.empty(), // This uses YOUR model, which is correct
      );

      if (existingTask.id.isNotEmpty) {
        throw Exception('Episode is already being downloaded');
      }

      final downloadUrl = await _trackingService.getEpisodeDownloadUrl(
        animeId,
        episodeNumber,
        quality,
      );

      final downloadPath = await getDownloadPath();
      final animeFolder = '$downloadPath/${_sanitizeFileName(animeTitle)}';
      final dir = Directory(animeFolder);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = '${_sanitizeFileName(animeTitle)}_Episode_${episodeNumber.toString().padLeft(2, '0')}.mp4';

      final taskId = await fd.FlutterDownloader.enqueue( // <<< FIX: Use prefix
        url: downloadUrl,
        savedDir: animeFolder,
        fileName: fileName,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        showNotification: true,
        openFileFromNotification: false,
      );

      if (taskId != null) {
        final downloadTask = DownloadTask(
          id: taskId,
          animeId: animeId,
          animeTitle: animeTitle,
          episodeNumber: episodeNumber,
          fileName: fileName,
          downloadPath: animeFolder,
          status: DownloadStatus.running, // This uses YOUR enum, which is correct
          progress: 0,
          createdAt: DateTime.now(),
        );

        _downloadTasks.add(downloadTask);
        await _saveDownloadTasks();
        _downloadTasksController.add(_downloadTasks);
      }
    } catch (e) {
      throw Exception('Failed to start download: $e');
    }
  }

  Future<void> pauseDownload(String taskId) async {
    try {
      await fd.FlutterDownloader.pause(taskId: taskId); // <<< FIX: Use prefix
      _updateTaskStatus(taskId, DownloadStatus.paused);
    } catch (e) {
      throw Exception('Failed to pause download: $e');
    }
  }

  Future<void> resumeDownload(String taskId) async {
    try {
      final newTaskId = await fd.FlutterDownloader.resume(taskId: taskId); // <<< FIX: Use prefix
      if (newTaskId != null) {
        _updateTaskId(taskId, newTaskId);
        _updateTaskStatus(newTaskId, DownloadStatus.running);
      }
    } catch (e) {
      throw Exception('Failed to resume download: $e');
    }
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      await fd.FlutterDownloader.cancel(taskId: taskId); // <<< FIX: Use prefix
      _removeTask(taskId);
    } catch (e) {
      throw Exception('Failed to cancel download: $e');
    }
  }

  Future<void> retryDownload(String taskId) async {
    try {
      final task = _downloadTasks.firstWhere((t) => t.id == taskId);
      await cancelDownload(taskId);

      await downloadEpisode(
        animeId: task.animeId,
        episodeNumber: task.episodeNumber,
        animeTitle: task.animeTitle,
      );
    } catch (e) {
      throw Exception('Failed to retry download: $e');
    }
  }

  Future<void> downloadAllEpisodes({
    required String animeId,
    required String animeTitle,
    required List<int> episodeNumbers,
    String quality = '720p',
  }) async {
    for (final episodeNumber in episodeNumbers) {
      try {
        await downloadEpisode(
          animeId: animeId,
          episodeNumber: episodeNumber,
          animeTitle: animeTitle,
          quality: quality,
        );
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('Failed to download episode $episodeNumber: $e');
      }
    }
  }

  List<DownloadTask> getActiveDownloads() {
    return _downloadTasks
        .where((task) =>
            task.status == DownloadStatus.running ||
            task.status == DownloadStatus.enqueued)
        .toList();
  }

  List<DownloadTask> getPausedDownloads() {
    return _downloadTasks
        .where((task) => task.status == DownloadStatus.paused)
        .toList();
  }

  List<DownloadTask> getCompletedDownloads() {
    return _downloadTasks
        .where((task) => task.status == DownloadStatus.complete)
        .toList();
  }

  List<DownloadTask> getFailedDownloads() {
    return _downloadTasks
        .where((task) => task.status == DownloadStatus.failed)
        .toList();
  }

  void _setupDownloadCallback() {
    fd.FlutterDownloader.registerCallback(_downloadCallback); // <<< FIX: Use prefix
  }

  @pragma('vm:entry-point')
  static void _downloadCallback(String id, int status, int progress) {
    // <<< FIX: Use `fd.DownloadTaskStatus` here
    final fd.DownloadTaskStatus downloadStatus = fd.DownloadTaskStatus.fromInt(status); 
    // Convert the integer status from the package into its own enum type.
    
    // Now convert the package's enum to YOUR enum before updating the state
    DownloadStatus localStatus = _convertStatus(downloadStatus);
    DownloadService()._updateTaskProgress(id, progress, localStatus);
  }

  // <<< ADD THIS HELPER METHOD
  static DownloadStatus _convertStatus(fd.DownloadTaskStatus status) {
    if (status == fd.DownloadTaskStatus.running) {
      return DownloadStatus.running;
    } else if (status == fd.DownloadTaskStatus.complete) {
      return DownloadStatus.complete;
    } else if (status == fd.DownloadTaskStatus.failed) {
      return DownloadStatus.failed;
    } else if (status == fd.DownloadTaskStatus.paused) {
      return DownloadStatus.paused;
    } else if (status == fd.DownloadTaskStatus.enqueued) {
      return DownloadStatus.enqueued;
    }
    return DownloadStatus.undefined; // Your enum should have an 'undefined' state
  }
  // <<< END OF ADDED HELPER METHOD

  void _updateTaskProgress(String taskId, int progress, DownloadStatus status) {
    final taskIndex = _downloadTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _downloadTasks[taskIndex] = _downloadTasks[taskIndex].copyWith(
        progress: progress,
        status: status,
      );

      if (status == DownloadStatus.complete) {
        final task = _downloadTasks[taskIndex];
        _trackingService.markEpisodeAsDownloaded(task.animeId, task.episodeNumber);
      }

      _saveDownloadTasks();
      _downloadTasksController.add(_downloadTasks);
    }
  }

  void _updateTaskStatus(String taskId, DownloadStatus status) {
    final taskIndex = _downloadTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _downloadTasks[taskIndex] = _downloadTasks[taskIndex].copyWith(status: status);
      _saveDownloadTasks();
      _downloadTasksController.add(_downloadTasks);
    }
  }

  void _updateTaskId(String oldTaskId, String newTaskId) {
    final taskIndex = _downloadTasks.indexWhere((task) => task.id == oldTaskId);
    if (taskIndex != -1) {
      _downloadTasks[taskIndex] = _downloadTasks[taskIndex].copyWith(id: newTaskId);
      _saveDownloadTasks();
      _downloadTasksController.add(_downloadTasks);
    }
  }

  void _removeTask(String taskId) {
    _downloadTasks.removeWhere((task) => task.id == taskId);
    _saveDownloadTasks();
    _downloadTasksController.add(_downloadTasks);
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> _loadDownloadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('download_tasks') ?? [];

      _downloadTasks.clear();
      for (final taskJsonString in tasksJson) { // <<< FIX: Iterate over strings
        try {
          // <<< FIX: Decode the string to a map first
          final task = DownloadTask.fromJson(json.decode(taskJsonString));
          _downloadTasks.add(task);
        } catch (e) {
          print('Failed to parse download task: $e');
        }
      }

      _downloadTasksController.add(_downloadTasks);
    } catch (e) {
      print('Failed to load download tasks: $e');
    }
  }

  Future<void> _saveDownloadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // <<< FIX: Encode each task's map to a JSON string
      final tasksJson = _downloadTasks.map((task) => json.encode(task.toJson())).toList();
      await prefs.setStringList('download_tasks', tasksJson);
    } catch (e) {
      print('Failed to save download tasks: $e');
    }
  }

  void dispose() {
    _downloadTasksController.close();
  }
}