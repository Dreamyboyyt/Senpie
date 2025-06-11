import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/anime_metadata.dart';
import 'anime_tracking_service.dart';
import 'settings_service.dart';

class LibraryService {
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  final AnimeTrackingService _trackingService = AnimeTrackingService();
  final SettingsService _settingsService = SettingsService();

  Future<String> exportLibrary() async {
    try {
      // Get all tracked anime
      final trackedAnime = _trackingService.trackedAnime;
      
      // Get current settings
      final settings = await _settingsService.exportSettings();
      
      // Create export data
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'settings': settings,
        'anime': trackedAnime.map((anime) => {
          'id': anime.id,
          'title': anime.title,
          'url': anime.url,
          'imageUrl': anime.imageUrl,
          'source': anime.source,
          'totalEpisodes': anime.totalEpisodes,
          'status': anime.status,
          'autoDownload': anime.autoDownload,
          'dateAdded': anime.dateAdded.toIso8601String(),
          'lastChecked': anime.lastChecked.toIso8601String(),
          'episodes': anime.episodes.map((episode) => {
            'episodeNumber': episode.episodeNumber,
            'title': episode.title,
            'url': episode.url,
            'isDownloaded': episode.isDownloaded,
            'isWatched': episode.isWatched,
            'downloadPath': episode.downloadPath,
            'addedAt': episode.addedAt.toIso8601String(),
          }).toList(),
        }).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'senpie_library_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export library: $e');
    }
  }

  Future<void> importLibrary(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file not found');
      }

      final jsonString = await file.readAsString();
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate import data
      if (!importData.containsKey('version') || !importData.containsKey('anime')) {
        throw Exception('Invalid import file format');
      }

      // Import settings if available
      if (importData.containsKey('settings')) {
        final settings = importData['settings'] as Map<String, dynamic>;
        await _settingsService.importSettings(settings);
      }

      // Import anime data
      final animeList = importData['anime'] as List<dynamic>;
      
      for (final animeData in animeList) {
        try {
          final anime = _parseImportedAnime(animeData as Map<String, dynamic>);
          
          // Check if anime already exists (by title and source since url doesn't exist)
          final existingAnime = _trackingService.trackedAnime
              .where((a) => a.title == anime.title && a.source == anime.source)
              .firstOrNull;
          
          if (existingAnime == null) {
            // Add new anime
            await _trackingService.addAnimeToTracking(
              AnimeMetadata(
                id: anime.id,
                title: anime.title,
                image: anime.imageUrl,
                description: 'Imported anime',
                airingStatus: AiringStatus.ongoing,
                genres: [],
                startEpisode: 1,
                endEpisode: anime.episodes.isNotEmpty ? anime.episodes.length : 1,
                recommendedAnime: [],
              ),
              anime.source,
            );
          } else {
            // Update existing anime episodes
            for (final episode in anime.episodes) {
              if (episode.isWatched) {
                await _trackingService.markEpisodeAsWatched(
                  existingAnime.id,
                  episode.episodeNumber,
                );
              }
              if (episode.isDownloaded) {
                await _trackingService.markEpisodeAsDownloaded(
                  existingAnime.id,
                  episode.episodeNumber,
                );
              }
            }
          }
        } catch (e) {
          print('Failed to import anime: $e');
          // Continue with next anime
        }
      }
    } catch (e) {
      throw Exception('Failed to import library: $e');
    }
  }

  Future<String?> selectImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to select import file: $e');
    }
  }

  Future<void> shareLibrary() async {
    try {
      final exportPath = await exportLibrary();
      await Share.shareXFiles(
        [XFile(exportPath)],
        text: 'Senpie Library Export',
        subject: 'My Anime Library',
      );
    } catch (e) {
      throw Exception('Failed to share library: $e');
    }
  }

  Future<Map<String, dynamic>> getLibraryStats() async {
    try {
      final trackedAnime = _trackingService.trackedAnime;
      
      final totalAnime = trackedAnime.length;
      final totalEpisodes = trackedAnime.fold<int>(
        0,
        (sum, anime) => sum + anime.episodes.length,
      );
      final downloadedEpisodes = trackedAnime.fold<int>(
        0,
        (sum, anime) => sum + anime.episodes.where((ep) => ep.isDownloaded).length,
      );
      final watchedEpisodes = trackedAnime.fold<int>(
        0,
        (sum, anime) => sum + anime.episodes.where((ep) => ep.isWatched).length,
      );

      // Calculate source distribution
      final sourceStats = <String, int>{};
      for (final anime in trackedAnime) {
        sourceStats[anime.source] = (sourceStats[anime.source] ?? 0) + 1;
      }

      // Calculate auto-download distribution
      final autoDownloadStats = <String, int>{};
      final autoDownloadCount = trackedAnime.where((anime) => anime.autoDownload).length;
      autoDownloadStats['Auto Download'] = autoDownloadCount;
      autoDownloadStats['Manual Download'] = totalAnime - autoDownloadCount;

      return {
        'totalAnime': totalAnime,
        'totalEpisodes': totalEpisodes,
        'downloadedEpisodes': downloadedEpisodes,
        'watchedEpisodes': watchedEpisodes,
        'downloadProgress': totalEpisodes > 0 ? downloadedEpisodes / totalEpisodes : 0.0,
        'watchProgress': totalEpisodes > 0 ? watchedEpisodes / totalEpisodes : 0.0,
        'sourceStats': sourceStats,
        'autoDownloadStats': autoDownloadStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get library stats: $e');
    }
  }

  Future<void> cleanupLibrary() async {
    try {
      final trackedAnime = _trackingService.trackedAnime;
      final animesToRemove = <String>[];

      for (final anime in trackedAnime) {
        // Remove anime with no episodes and not updated in 30 days
        if (anime.episodes.isEmpty && 
            DateTime.now().difference(anime.lastChecked).inDays > 30) {
          animesToRemove.add(anime.id);
        }
      }

      for (final animeId in animesToRemove) {
        await _trackingService.removeAnimeFromTracking(animeId);
      }
    } catch (e) {
      throw Exception('Failed to cleanup library: $e');
    }
  }

  TrackedAnime _parseImportedAnime(Map<String, dynamic> data) {
    final episodes = (data['episodes'] as List<dynamic>?)
        ?.map((episodeData) => _parseImportedEpisode(episodeData as Map<String, dynamic>))
        .toList() ?? <EpisodeInfo>[];

    return TrackedAnime(
      id: data['id'] as String? ?? '',
      title: data['title'] as String,
      imageUrl: data['imageUrl'] as String? ?? '',
      source: data['source'] as String,
      episodes: episodes,
      lastChecked: DateTime.parse(data['lastChecked'] as String),
      dateAdded: DateTime.parse(data['addedAt'] as String),
      autoDownload: data['autoDownload'] as bool? ?? false,
    );
  }

  EpisodeInfo _parseImportedEpisode(Map<String, dynamic> data) {
    return EpisodeInfo(
      episodeNumber: data['episodeNumber'] as int,
      downloadUrl: data['downloadUrl'] as String? ?? '',
      quality: data['quality'] as String? ?? '720p',
      fileSize: data['fileSize'] as int? ?? 0,
      isDownloaded: data['isDownloaded'] as bool? ?? false,
      isWatched: data['isWatched'] as bool? ?? false,
    );
  }
}

