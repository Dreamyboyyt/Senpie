// lib/services/gogo_scraper.dart

import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:dio/dio.dart';
import '../models/anime_metadata.dart';
import '../utils/constants.dart';
import 'base_scraper.dart';

// --- FIX: COMBINED INTO ONE CORRECT CLASS DEFINITION ---
class GogoScraper extends BaseScraper {
  final Dio _dio = Dio(); // <<< The Dio instance now lives inside the correct class

  GogoScraper() : super(siteName: GogoConstants.siteName, baseUrl: GogoConstants.baseUrl);

  @override
  Future<List<SearchResult>> search(String keyword, {bool ignoreDub = true}) async {
    try {
      final searchUrl = '${GogoConstants.ajaxSearchUrl}?keyword=$keyword';
      
      // FIX: Use the _dio instance from the class
      final response = await _dio.get(searchUrl); 
      final jsonData = json.decode(response.data); // Assuming the response is a JSON string

      final content = jsonData['content'] as String;
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

      if (ignoreDub) {
        final filteredResults = <SearchResult>[];
        final subTitles = <String>{};

        for (final result in results) {
          if (!result.title.contains(GogoConstants.dubExtension)) {
            subTitles.add(result.title);
          }
        }

        for (final result in results) {
          if (result.title.contains(GogoConstants.dubExtension)) {
            final subTitle =
                result.title.replaceAll(GogoConstants.dubExtension, '');
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

  // --- All your other methods (getAnimeMetadata, etc.) remain unchanged ---
  // --- just make sure they are inside this class's closing brace.   ---

  @override
  Future<AnimeMetadata> getAnimeMetadata(String animeUrl) async {
    try {
      // FIX: Use fetchDocument from the BaseScraper
      final document = await fetchDocument(animeUrl);
      
      // The rest of this method seems correct
      final movieIdInput = document.querySelector('input#movie_id');
      final animeId = movieIdInput?.attributes['value'] ?? '';
      
      final titleElement = document.querySelector('h1.anime_info_body_bg h2');
      final title = titleElement?.text.trim() ?? '';
      
      final imageElement = document.querySelector('div.anime_info_body_bg img');
      final image = imageElement?.attributes['src'] ?? '';
      
      final descriptionElement = document.querySelector('div.anime_info_body_bg p.type:nth-of-type(2)');
      final description = descriptionElement?.text.replaceFirst('Plot Summary: ', '').trim() ?? '';
      
      final statusElement = document.querySelector('div.anime_info_body_bg p.type:nth-of-type(1) a');
      final statusText = statusElement?.text.trim() ?? '';
      final airingStatus = statusText.toLowerCase().contains('ongoing') 
          ? AiringStatus.ongoing 
          : AiringStatus.completed;
      
      final genreElements = document.querySelectorAll('div.anime_info_body_bg p.type:nth-of-type(3) a');
      final genres = genreElements.map((e) => e.text.trim()).toList();
      
      final episodeListUrl = '${GogoConstants.ajaxLoadEpsUrl}?ep_start=0&ep_end=10000&id=$animeId';
      final episodeDocument = await fetchDocument(episodeListUrl);
      final episodeElements = episodeDocument.querySelectorAll('li a');
      
      int startEpisode = 1;
      int endEpisode = 1;
      
      if (episodeElements.isNotEmpty) {
        final latestEpisode = episodeElements.first.attributes['ep_end'];
        final firstEpisode = episodeElements.last.attributes['ep_start'];
        
        startEpisode = int.tryParse(firstEpisode ?? '1') ?? 1;
        endEpisode = int.tryParse(latestEpisode ?? '1') ?? 1;
      }
      
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
      
      final downloadSection = document.querySelector('div.cf-download');
      if (downloadSection == null) {
        throw ScrapingException('Download section not found');
      }
      
      final downloadLinks = downloadSection.querySelectorAll('a');
      
      // I am assuming findClosestQualityIndex is in your BaseScraper
      // If not, you'll need to define it here.
      final qualityIndex = findClosestQualityIndex(
          downloadLinks.map((a) => a.text.trim()).toList(), 
          quality
      );
      
      final selectedLink = downloadLinks[qualityIndex];
      final directUrl = selectedLink.attributes['href'] ?? '';
      
      if (directUrl.isEmpty) {
        throw ScrapingException('Direct download URL not found');
      }
      
      final response = await _dio.head(directUrl, options: Options(
        followRedirects: true,
        maxRedirects: 5,
      ));
      
      return response.realUri.toString();
    } catch (e) {
      throw ScrapingException('Failed to get direct download link from Gogoanime: $e');
    }
  }
}
