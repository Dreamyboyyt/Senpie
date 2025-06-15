import 'dart:math';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/anime_metadata.dart';

abstract class BaseScraper {
  late final Dio _dio;
  final String siteName;
  final String baseUrl;

  BaseScraper({required this.siteName, required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': _getRandomUserAgent(),
      },
    ));

    // Add retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 429 ||
              error.response?.statusCode == 503) {
            // Rate limited or service unavailable, wait and retry
            await Future.delayed(const Duration(seconds: 5));
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, continue with original error
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  String _getRandomUserAgent() {
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/117.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/117.0',
    ];
    return userAgents[Random().nextInt(userAgents.length)];
  }

  Future<Document> fetchDocument(String url) async {
    try {
      final response = await _dio.get(url);
      return html_parser.parse(response.data);
    } catch (e) {
      throw ScrapingException('Failed to fetch document from $url: $e');
    }
  }

  Future<Map<String, dynamic>> fetchJson(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ScrapingException('Failed to fetch JSON from $url: $e');
    }
  }

  String sanitizeTitle(String title) {
    return title.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '');
  }

  int findClosestQualityIndex(List<String> qualities, String userQuality) {
    if (qualities.contains(userQuality)) {
      return qualities.indexOf(userQuality);
    }

    // Extract quality numbers for comparison
    final userQualityNum = _extractQualityNumber(userQuality);
    if (userQualityNum == null) return 0;

    int closestIndex = 0;
    int closestDiff = double.maxFinite.toInt();

    for (int i = 0; i < qualities.length; i++) {
      final qualityNum = _extractQualityNumber(qualities[i]);
      if (qualityNum != null) {
        final diff = (userQualityNum - qualityNum).abs();
        if (diff < closestDiff) {
          closestDiff = diff;
          closestIndex = i;
        }
      }
    }

    return closestIndex;
  }

  int? _extractQualityNumber(String quality) {
    final match = RegExp(r'(\d{3,4})p').firstMatch(quality);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<int> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.parse(contentLength) : 0;
    } catch (e) {
      return 0;
    }
  }

  // Abstract methods to be implemented by specific scrapers
  Future<List<SearchResult>> search(String keyword);
  Future<AnimeMetadata> getAnimeMetadata(String animeUrl);
  Future<List<String>> getEpisodeDownloadLinks(
    String animeId,
    int startEpisode,
    int endEpisode,
    String quality,
  );
  Future<String> getDirectDownloadLink(String episodeUrl, String quality);
}

class ScrapingException implements Exception {
  final String message;
  ScrapingException(this.message);

  @override
  String toString() => 'ScrapingException: $message';
}

