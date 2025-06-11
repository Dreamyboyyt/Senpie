import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime_metadata.dart';
import '../utils/constants.dart';
import 'gogo_scraper.dart';
import 'pahe_scraper.dart';
import 'base_scraper.dart';

class AnimeTrackingService {
  static final AnimeTrackingService _instance = AnimeTrackingService._internal();
  factory AnimeTrackingService() => _instance;
  AnimeTrackingService._internal();

  final GogoScraper _gogoScraper = GogoScraper();
  final PaheScraper _paheScraper = PaheScraper();
  
  final StreamController<List<TrackedAnime>> _trackedAnimeController = 
      StreamController<List<TrackedAnime>>.broadcast();
  
  List<TrackedAnime> _trackedAnime = [];
  
  Stream<List<TrackedAnime>> get trackedAnimeStream => _trackedAnimeController.stream;
  List<TrackedAnime> get trackedAnime => List.unmodifiable(_trackedAnime);

  Future<void> initialize() async {
    await _loadTrackedAnime();
  }

  Future<List<SearchResult>> searchAnime(String keyword, String source) async {
    try {
      final scraper = _getScraper(source);
      return await scraper.search(keyword);
    } catch (e) {
      throw Exception('Failed to search anime: $e');
    }
  }

  Future<AnimeMetadata> getAnimeMetadata(String animeUrl, String source) async {
    try {
      final scraper = _getScraper(source);
      return await scraper.getAnimeMetadata(animeUrl);
    } catch (e) {
      throw Exception('Failed to get anime metadata: $e');
    }
  }

  Future<void> addAnimeToTracking(AnimeMetadata metadata, String source) async {
    try {
      // Check if anime is already being tracked
      final existingIndex = _trackedAnime.indexWhere((anime) => anime.id == metadata.id);
      if (existingIndex != -1) {
        throw Exception('Anime is already being tracked');
      }

      // Create initial episode list
      final episodes = <EpisodeInfo>[];
      for (int i = metadata.startEpisode; i <= metadata.endEpisode; i++) {
        episodes.add(EpisodeInfo(
          episodeNumber: i,
          downloadUrl: '',
          quality: AppConstants.defaultQuality,
          fileSize: 0,
        ));
      }

      final trackedAnime = TrackedAnime(
        id: metadata.id,
        title: metadata.title,
        imageUrl: metadata.image,
        source: source,
        episodes: episodes,
        lastChecked: DateTime.now(),
        dateAdded: DateTime.now(),
        autoDownload: true,
      );

      _trackedAnime.add(trackedAnime);
      await _saveTrackedAnime();
      _trackedAnimeController.add(_trackedAnime);
    } catch (e) {
      throw Exception('Failed to add anime to tracking: $e');
    }
  }

  Future<void> removeAnimeFromTracking(String animeId) async {
    try {
      _trackedAnime.removeWhere((anime) => anime.id == animeId);
      await _saveTrackedAnime();
      _trackedAnimeController.add(_trackedAnime);
    } catch (e) {
      throw Exception('Failed to remove anime from tracking: $e');
    }
  }

  Future<void> updateAnimeEpisodes(String animeId) async {
    try {
      final animeIndex = _trackedAnime.indexWhere((anime) => anime.id == animeId);
      if (animeIndex == -1) {
        throw Exception('Anime not found in tracking list');
      }

      final anime = _trackedAnime[animeIndex];
      final scraper = _getScraper(anime.source);
      
      // Get updated metadata to check for new episodes
      final animeUrl = anime.source == 'gogo' 
          ? '${GogoConstants.baseUrl}/category/${anime.id}'
          : '${PaheConstants.animePageUrl}${anime.id}';
      
      final updatedMetadata = await scraper.getAnimeMetadata(animeUrl);
      
      // Check if there are new episodes
      final currentMaxEpisode = anime.episodes.isNotEmpty 
          ? anime.episodes.map((e) => e.episodeNumber).reduce((a, b) => a > b ? a : b)
          : 0;
      
      if (updatedMetadata.endEpisode > currentMaxEpisode) {
        // Add new episodes
        final newEpisodes = <EpisodeInfo>[];
        for (int i = currentMaxEpisode + 1; i <= updatedMetadata.endEpisode; i++) {
          newEpisodes.add(EpisodeInfo(
            episodeNumber: i,
            downloadUrl: '',
            quality: AppConstants.defaultQuality,
            fileSize: 0,
          ));
        }

        final updatedAnime = anime.copyWith(
          episodes: [...anime.episodes, ...newEpisodes],
          lastChecked: DateTime.now(),
        );

        _trackedAnime[animeIndex] = updatedAnime;
        await _saveTrackedAnime();
        _trackedAnimeController.add(_trackedAnime);
      }
    } catch (e) {
      throw Exception('Failed to update anime episodes: $e');
    }
  }

  Future<void> checkAllAnimeForUpdates() async {
    for (final anime in _trackedAnime) {
      try {
        await updateAnimeEpisodes(anime.id);
        // Add a small delay to avoid overwhelming the servers
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        // Log error but continue with other anime
        print('Failed to update ${anime.title}: $e');
      }
    }
  }

  Future<String> getEpisodeDownloadUrl(String animeId, int episodeNumber, String quality) async {
    try {
      final anime = _trackedAnime.firstWhere((anime) => anime.id == animeId);
      final scraper = _getScraper(anime.source);
      
      // Get episode download links
      final episodeLinks = await scraper.getEpisodeDownloadLinks(
        animeId,
        episodeNumber,
        episodeNumber,
        quality,
      );
      
      if (episodeLinks.isEmpty) {
        throw Exception('No download links found for episode $episodeNumber');
      }
      
      // Get direct download link
      final directLink = await scraper.getDirectDownloadLink(episodeLinks.first, quality);
      return directLink;
    } catch (e) {
      throw Exception('Failed to get episode download URL: $e');
    }
  }

  Future<void> markEpisodeAsDownloaded(String animeId, int episodeNumber) async {
    try {
      final animeIndex = _trackedAnime.indexWhere((anime) => anime.id == animeId);
      if (animeIndex == -1) return;

      final anime = _trackedAnime[animeIndex];
      final episodeIndex = anime.episodes.indexWhere((ep) => ep.episodeNumber == episodeNumber);
      if (episodeIndex == -1) return;

      final updatedEpisode = anime.episodes[episodeIndex].copyWith(isDownloaded: true);
      final updatedEpisodes = List<EpisodeInfo>.from(anime.episodes);
      updatedEpisodes[episodeIndex] = updatedEpisode;

      final updatedAnime = anime.copyWith(episodes: updatedEpisodes);
      _trackedAnime[animeIndex] = updatedAnime;

      await _saveTrackedAnime();
      _trackedAnimeController.add(_trackedAnime);
    } catch (e) {
      throw Exception('Failed to mark episode as downloaded: $e');
    }
  }

  Future<void> markEpisodeAsWatched(String animeId, int episodeNumber) async {
    try {
      final animeIndex = _trackedAnime.indexWhere((anime) => anime.id == animeId);
      if (animeIndex == -1) return;

      final anime = _trackedAnime[animeIndex];
      final episodeIndex = anime.episodes.indexWhere((ep) => ep.episodeNumber == episodeNumber);
      if (episodeIndex == -1) return;

      final updatedEpisode = anime.episodes[episodeIndex].copyWith(isWatched: true);
      final updatedEpisodes = List<EpisodeInfo>.from(anime.episodes);
      updatedEpisodes[episodeIndex] = updatedEpisode;

      final updatedAnime = anime.copyWith(episodes: updatedEpisodes);
      _trackedAnime[animeIndex] = updatedAnime;

      await _saveTrackedAnime();
      _trackedAnimeController.add(_trackedAnime);
    } catch (e) {
      throw Exception('Failed to mark episode as watched: $e');
    }
  }

  BaseScraper _getScraper(String source) {
    switch (source.toLowerCase()) {
      case 'gogo':
        return _gogoScraper;
      case 'pahe':
        return _paheScraper;
      default:
        throw Exception('Unknown scraper source: $source');
    }
  }

  Future<void> _loadTrackedAnime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackedAnimeJson = prefs.getStringList('tracked_anime') ?? [];
      
      _trackedAnime = trackedAnimeJson
          .map((json) => TrackedAnime.fromJson(jsonDecode(json)))
          .toList();
      
      _trackedAnimeController.add(_trackedAnime);
    } catch (e) {
      print('Failed to load tracked anime: $e');
      _trackedAnime = [];
    }
  }

  Future<void> _saveTrackedAnime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackedAnimeJson = _trackedAnime
          .map((anime) => jsonEncode(anime.toJson()))
          .toList();
      
      await prefs.setStringList('tracked_anime', trackedAnimeJson);
    } catch (e) {
      print('Failed to save tracked anime: $e');
    }
  }

  void dispose() {
    _trackedAnimeController.close();
  }
}

