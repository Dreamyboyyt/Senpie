import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/anime_metadata.dart';
import '../utils/constants.dart';
import 'base_scraper.dart';

class PaheScraper extends BaseScraper {
  // Cookies needed for Animepahe requests
  final Map<String, String> _cookies = {
    '__ddg1_': '',
    '__ddg2_': '',
  };
  
  late Dio _dio;

  PaheScraper() : super(siteName: PaheConstants.siteName, baseUrl: PaheConstants.baseUrl) {
    _dio = Dio();
    // Add cookie interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add cookies to requests
          if (_cookies.isNotEmpty) {
            final cookieString = _cookies.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('; ');
            options.headers['Cookie'] = cookieString;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Update cookies from response
          final setCookieHeaders = response.headers['set-cookie'];
          if (setCookieHeaders != null) {
            for (final cookie in setCookieHeaders) {
              final parts = cookie.split(';')[0].split('=');
              if (parts.length == 2) {
                _cookies[parts[0]] = parts[1];
              }
            }
          }
          handler.next(response);
        },
      ),
    );
  }

  @override
  Future<List<SearchResult>> search(String keyword) async {
    try {
      final searchUrl = '${PaheConstants.apiEntryPoint}search&q=$keyword';
      final response = await _makeApiRequest(searchUrl);
      
      final data = response['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return [];
      }
      
      final results = <SearchResult>[];
      for (final item in data) {
        final itemMap = item as Map<String, dynamic>;
        final title = itemMap['title'] as String? ?? '';
        final session = itemMap['session'] as String? ?? '';
        final url = '${PaheConstants.animePageUrl}$session';
        
        results.add(SearchResult(
          title: title,
          url: url,
          id: session,
        ));
      }
      
      return results;
    } catch (e) {
      throw ScrapingException('Failed to search on Animepahe: $e');
    }
  }

  @override
  Future<AnimeMetadata> getAnimeMetadata(String animeUrl) async {
    try {
      final document = await _fetchDocumentWithCookies(animeUrl);
      
      // Extract anime ID from URL
      final uri = Uri.parse(animeUrl);
      final animeId = uri.pathSegments.last;
      
      // Extract anime title
      final titleElement = document.querySelector('h1.title');
      final title = titleElement?.text.trim() ?? '';
      
      // Extract anime image
      final imageElement = document.querySelector('div.anime-poster img');
      final image = imageElement?.attributes['src'] ?? '';
      
      // Extract description
      final descriptionElement = document.querySelector('div.anime-synopsis p');
      final description = descriptionElement?.text.trim() ?? '';
      
      // Extract airing status
      final statusElement = document.querySelector('div.anime-status span');
      final statusText = statusElement?.text.trim() ?? '';
      final airingStatus = statusText.toLowerCase().contains('ongoing') 
          ? AiringStatus.ongoing 
          : AiringStatus.completed;
      
      // Extract genres
      final genreElements = document.querySelectorAll('div.anime-genres a');
      final genres = genreElements.map((e) => e.text.trim()).toList();
      
      // Get episode information
      final episodesUrl = '${PaheConstants.loadEpisodesUrl}$animeId&page=1';
      final episodesResponse = await _makeApiRequest(episodesUrl);
      
      final episodesData = episodesResponse['data'] as List<dynamic>?;
      int startEpisode = 1;
      int endEpisode = 1;
      
      if (episodesData != null && episodesData.isNotEmpty) {
        final firstEpisodeData = episodesData.first as Map<String, dynamic>;
        final lastEpisodeData = episodesData.last as Map<String, dynamic>;
        
        startEpisode = (firstEpisodeData['episode'] as int?) ?? 1;
        endEpisode = (lastEpisodeData['episode'] as int?) ?? 1;
      }
      
      // Get recommended anime (if available)
      final recommendedElements = document.querySelectorAll('div.anime-recommendations a');
      final recommendedAnime = recommendedElements.map((element) {
        final title = element.text.trim();
        final href = element.attributes['href'];
        final url = href != null ? '${PaheConstants.baseUrl}$href' : '';
        return RecommendedAnime(title: title, url: url);
      }).toList();
      
      return AnimeMetadata(
        id: animeId,
        title: title,
        image: image,
        description: description,
        airingStatus: airingStatus,
        genres: genres,
        startEpisode: startEpisode,
        endEpisode: endEpisode,
        recommendedAnime: recommendedAnime,
      );
    } catch (e) {
      throw ScrapingException('Failed to get anime metadata from Animepahe: $e');
    }
  }

  @override
  Future<List<String>> getEpisodeDownloadLinks(
    String animeId,
    int startEpisode,
    int endEpisode,
    String quality,
  ) async {
    try {
      final episodePageLinks = <String>[];
      
      // Get episodes info with pagination
      final episodesInfo = await _getEpisodePagesInfo(animeId, startEpisode, endEpisode);
      
      for (int page = episodesInfo['startPage']!; page <= episodesInfo['endPage']!; page++) {
        final episodesUrl = '${PaheConstants.loadEpisodesUrl}$animeId&page=$page';
        final response = await _makeApiRequest(episodesUrl);
        
        final episodesData = response['data'] as List<dynamic>?;
        if (episodesData != null) {
          for (final episodeData in episodesData) {
            final episodeMap = episodeData as Map<String, dynamic>;
            final episodeNum = (episodeMap['episode'] as int?) ?? 0;
            final session = episodeMap['session'] as String? ?? '';
            
            if (episodeNum >= startEpisode && episodeNum <= endEpisode) {
              final episodeUrl = '${PaheConstants.episodePageUrl}$animeId/$session';
              episodePageLinks.add(episodeUrl);
            }
          }
        }
      }
      
      return episodePageLinks;
    } catch (e) {
      throw ScrapingException('Failed to get episode download links from Animepahe: $e');
    }
  }

  @override
  Future<String> getDirectDownloadLink(String episodeUrl, String quality) async {
    try {
      final document = await _fetchDocumentWithCookies(episodeUrl);
      
      // Find the download link - this is a simplified version
      // The actual implementation would need to handle the complex JavaScript
      // decoding that Animepahe uses for their download links
      
      final downloadElements = document.querySelectorAll('a[href*="kwik"]');
      if (downloadElements.isEmpty) {
        throw ScrapingException('No download links found');
      }
      
      // For now, return the first kwik link
      // In a full implementation, you'd need to:
      // 1. Extract the encoded URL from JavaScript
      // 2. Decode it using the same algorithm as the original Python code
      // 3. Follow the redirect chain to get the final download URL
      
      final kwikUrl = downloadElements.first.attributes['href'] ?? '';
      if (kwikUrl.isEmpty) {
        throw ScrapingException('Kwik URL not found');
      }
      
      // This is a placeholder - the actual implementation would need
      // to handle the complex decoding process
      return kwikUrl;
    } catch (e) {
      throw ScrapingException('Failed to get direct download link from Animepahe: $e');
    }
  }

  Future<Map<String, dynamic>> _makeApiRequest(String url) async {
    try {
      final response = await _dio.get(url);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Handle domain changes
      if (e is DioException && e.response?.statusCode == 404) {
        // In a full implementation, you'd update the domain here
        // similar to the Python version
      }
      rethrow;
    }
  }

  Future<Document> _fetchDocumentWithCookies(String url) async {
    try {
      final response = await _dio.get(url);
      return html_parser.parse(response.data);
    } catch (e) {
      throw ScrapingException('Failed to fetch document from $url: $e');
    }
  }

  Future<Map<String, int>> _getEpisodePagesInfo(
    String animeId,
    int startEpisode,
    int endEpisode,
  ) async {
    // Get first page to determine pagination info
    final firstPageUrl = '${PaheConstants.loadEpisodesUrl}$animeId&page=1';
    final response = await _makeApiRequest(firstPageUrl);
    
    final perPage = (response['per_page'] as int?) ?? 30;
    final startPage = ((startEpisode - 1) / perPage).ceil() + 1;
    final endPage = ((endEpisode - 1) / perPage).ceil() + 1;
    
    return {
      'startPage': startPage,
      'endPage': endPage,
      'perPage': perPage,
    };
  }

  // Helper method to extract anime title, page link, and ID from search result
  Map<String, String> extractAnimeInfo(Map<String, dynamic> searchResult) {
    final title = searchResult['title'] as String? ?? '';
    final session = searchResult['session'] as String? ?? '';
    final pageLink = '${PaheConstants.animePageUrl}$session';
    
    return {
      'title': title,
      'pageLink': pageLink,
      'animeId': session,
    };
  }
}

