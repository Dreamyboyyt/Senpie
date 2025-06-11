import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:dio/dio.dart';
import '../models/anime_metadata.dart';
import '../utils/constants.dart';
import 'base_scraper.dart';

class GogoScraper {
  final Dio _dio = Dio();
class GogoScraper extends BaseScraper {
  GogoScraper() : super(siteName: GogoConstants.siteName, baseUrl: GogoConstants.baseUrl);

  @override
  Future<List<SearchResult>> search(String keyword, {bool ignoreDub = true}) async {
    try {
      final searchUrl = '${GogoConstants.ajaxSearchUrl}?keyword=$keyword';
      final response = await fetchJson(searchUrl);
      
      final content = response['content'] as String;
      final document = html_parser.parse(content);
      final linkElements = document.querySelectorAll('a');
      
      final results = <SearchResult>[];
      
      for (final element in linkElements) {
        final title = element.text.trim();
        final href = element.attributes['href'];
        
        if (title.isNotEmpty && href != null) {
          final url = '${GogoConstants.baseUrl}$href';
          results.add(SearchResult(title: title, url: url));
        }
      }
      
      // Filter out dub versions if requested
      if (ignoreDub) {
        final filteredResults = <SearchResult>[];
        final subTitles = <String>{};
        
        // First pass: collect sub titles
        for (final result in results) {
          if (!result.title.contains(GogoConstants.dubExtension)) {
            subTitles.add(result.title);
          }
        }
        
        // Second pass: filter out dubs that have sub versions
        for (final result in results) {
          if (result.title.contains(GogoConstants.dubExtension)) {
            final subTitle = result.title.replaceAll(GogoConstants.dubExtension, '');
            if (!subTitles.contains(subTitle)) {
              filteredResults.add(result);
            }
          } else {
            filteredResults.add(result);
          }
        }
        
        return filteredResults;
      }
      
      return results;
    } catch (e) {
      throw ScrapingException('Failed to search on Gogoanime: $e');
    }
  }

  @override
  Future<AnimeMetadata> getAnimeMetadata(String animeUrl) async {
    try {
      final document = await fetchDocument(animeUrl);
      
      // Extract anime ID from the page
      final movieIdInput = document.querySelector('input#movie_id');
      final animeId = movieIdInput?.attributes['value'] ?? '';
      
      // Extract anime title
      final titleElement = document.querySelector('h1.anime_info_body_bg h2');
      final title = titleElement?.text.trim() ?? '';
      
      // Extract anime image
      final imageElement = document.querySelector('div.anime_info_body_bg img');
      final image = imageElement?.attributes['src'] ?? '';
      
      // Extract description
      final descriptionElement = document.querySelector('div.anime_info_body_bg p.type:nth-of-type(2)');
      final description = descriptionElement?.text.replaceFirst('Plot Summary: ', '').trim() ?? '';
      
      // Extract airing status
      final statusElement = document.querySelector('div.anime_info_body_bg p.type:nth-of-type(1) a');
      final statusText = statusElement?.text.trim() ?? '';
      final airingStatus = statusText.toLowerCase().contains('ongoing') 
          ? AiringStatus.ongoing 
          : AiringStatus.completed;
      
      // Extract genres
      final genreElements = document.querySelectorAll('div.anime_info_body_bg p.type:nth-of-type(3) a');
      final genres = genreElements.map((e) => e.text.trim()).toList();
      
      // Get episode information
      final episodeListUrl = '${GogoConstants.ajaxLoadEpsUrl}?ep_start=0&ep_end=10000&id=$animeId';
      final episodeDocument = await fetchDocument(episodeListUrl);
      final episodeElements = episodeDocument.querySelectorAll('li a');
      
      int startEpisode = 1;
      int endEpisode = 1;
      
      if (episodeElements.isNotEmpty) {
        // Episodes are in reverse order, so first is the latest
        final latestEpisode = episodeElements.first.attributes['ep_end'];
        final firstEpisode = episodeElements.last.attributes['ep_start'];
        
        startEpisode = int.tryParse(firstEpisode ?? '1') ?? 1;
        endEpisode = int.tryParse(latestEpisode ?? '1') ?? 1;
      }
      
      // Get recommended anime (if available)
      final recommendedElements = document.querySelectorAll('div.anime_info_body_bg div.anime_info_body_bg_right ul li a');
      final recommendedAnime = recommendedElements.map((element) {
        final title = element.text.trim();
        final href = element.attributes['href'];
        final url = href != null ? '${GogoConstants.baseUrl}$href' : '';
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
      throw ScrapingException('Failed to get anime metadata from Gogoanime: $e');
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
      final episodeListUrl = '${GogoConstants.ajaxLoadEpsUrl}?ep_start=$startEpisode&ep_end=$endEpisode&id=$animeId';
      final document = await fetchDocument(episodeListUrl);
      final episodeElements = document.querySelectorAll('li a');
      
      final downloadLinks = <String>[];
      
      // Episodes are returned in reverse order, so reverse them
      final reversedElements = episodeElements.reversed.toList();
      
      for (final element in reversedElements) {
        final href = element.attributes['href'];
        if (href != null) {
          final episodeUrl = '${GogoConstants.baseUrl}$href';
          downloadLinks.add(episodeUrl);
        }
      }
      
      return downloadLinks;
    } catch (e) {
      throw ScrapingException('Failed to get episode download links from Gogoanime: $e');
    }
  }

  @override
  Future<String> getDirectDownloadLink(String episodeUrl, String quality) async {
    try {
      final document = await fetchDocument(episodeUrl);
      
      // Find download links section
      final downloadSection = document.querySelector('div.cf-download');
      if (downloadSection == null) {
        throw ScrapingException('Download section not found');
      }
      
      final downloadLinks = downloadSection.querySelectorAll('a');
      final qualities = downloadLinks.map((a) => a.text.trim()).toList();
      
      if (qualities.isEmpty) {
        throw ScrapingException('No download links found');
      }
      
      final qualityIndex = findClosestQualityIndex(qualities, quality);
      final selectedLink = downloadLinks[qualityIndex];
      final directUrl = selectedLink.attributes['href'] ?? '';
      
      if (directUrl.isEmpty) {
        throw ScrapingException('Direct download URL not found');
      }
      
      // Follow redirects to get the final download URL
      final response = await _dio.head(directUrl, options: Options(
        followRedirects: true,
        maxRedirects: 5,
      ));
      
      return response.realUri.toString();
    } catch (e) {
      throw ScrapingException('Failed to get direct download link from Gogoanime: $e');
    }
  }

  bool titleIsDub(String title) {
    return title.contains(GogoConstants.dubExtension);
  }

  Future<List<String>> getHlsLinks(List<String> episodePageLinks) async {
    // Implementation for HLS links if needed for stability
    // This would be used as a fallback when direct downloads fail
    final hlsLinks = <String>[];
    
    for (final episodeUrl in episodePageLinks) {
      try {
        final document = await fetchDocument(episodeUrl);
        
        // Look for HLS/m3u8 links in the page
        final scripts = document.querySelectorAll('script');
        for (final script in scripts) {
          final content = script.text;
          final m3u8Match = RegExp(r'https?://[^\s"]+\.m3u8[^\s"]*').firstMatch(content);
          if (m3u8Match != null) {
            hlsLinks.add(m3u8Match.group(0)!);
            break;
          }
        }
      } catch (e) {
        // Continue with next episode if one fails
        continue;
      }
    }
    
    return hlsLinks;
  }
}

