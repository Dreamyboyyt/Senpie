// lib/models/anime_metadata.dart

import 'package:json_annotation/json_annotation.dart';

part 'anime_metadata.g.dart';

enum AiringStatus {
  @JsonValue('Ongoing')
  ongoing,
  @JsonValue('Completed')
  completed,
}

@JsonSerializable()
class AnimeMetadata {
  final String id;
  final String title;
  final String image;
  final String description;
  final AiringStatus airingStatus;
  final List<String> genres;
  final int startEpisode;
  final int endEpisode;
  final List<RecommendedAnime> recommendedAnime;

  const AnimeMetadata({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.airingStatus,
    required this.genres,
    required this.startEpisode,
    required this.endEpisode,
    required this.recommendedAnime,
  });

  factory AnimeMetadata.fromJson(Map<String, dynamic> json) =>
      _$AnimeMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AnimeMetadataToJson(this);
}

@JsonSerializable()
class RecommendedAnime {
  final String title;
  final String url;

  const RecommendedAnime({
    required this.title,
    required this.url,
  });

  factory RecommendedAnime.fromJson(Map<String, dynamic> json) =>
      _$RecommendedAnimeFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendedAnimeToJson(this);
}

@JsonSerializable()
class SearchResult {
  final String title;
  final String url;
  final String? id;

  const SearchResult({
    required this.title,
    required this.url,
    this.id,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultToJson(this);
}

@JsonSerializable()
class EpisodeInfo {
  final int episodeNumber;
  final String downloadUrl;
  final String quality;
  final int fileSize;
  final bool isDownloaded;
  final bool isWatched;

  // --- FIX: ADDED MISSING FIELDS FROM BUILD LOG ---
  final String? title;
  final String? url;
  final String? downloadPath;
  final DateTime? addedAt;
  // --- END OF FIX ---

  const EpisodeInfo({
    required this.episodeNumber,
    required this.downloadUrl,
    required this.quality,
    required this.fileSize,
    this.isDownloaded = false,
    this.isWatched = false,
    // --- FIX: ADDED TO CONSTRUCTOR ---
    this.title,
    this.url,
    this.downloadPath,
    this.addedAt,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) =>
      _$EpisodeInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeInfoToJson(this);

  EpisodeInfo copyWith({
    int? episodeNumber,
    String? downloadUrl,
    String? quality,
    int? fileSize,
    bool? isDownloaded,
    bool? isWatched,
    // --- FIX: ADDED TO COPYWITH ---
    String? title,
    String? url,
    String? downloadPath,
    DateTime? addedAt,
  }) {
    return EpisodeInfo(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      quality: quality ?? this.quality,
      fileSize: fileSize ?? this.fileSize,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isWatched: isWatched ?? this.isWatched,
      // --- FIX: ADDED HERE ---
      title: title ?? this.title,
      url: url ?? this.url,
      downloadPath: downloadPath ?? this.downloadPath,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

@JsonSerializable()
class TrackedAnime {
  final String id;
  final String title;
  final String imageUrl;
  final String source; // 'gogo' or 'pahe'
  final List<EpisodeInfo> episodes;
  final DateTime lastChecked;
  final DateTime dateAdded;
  final bool autoDownload;

  // --- FIX: ADDED MISSING FIELDS FROM BUILD LOG ---
  final String? url;
  final String? status;
  final int? totalEpisodes;
  // Note: 'addedAt' was already in your log, but the field name here is 'dateAdded'.
  // We'll assume `library_service` meant to use `dateAdded` and fix that file next.
  // We are adding the other fields here.
  // --- END OF FIX ---

  const TrackedAnime({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.source,
    required this.episodes,
    required this.lastChecked,
    required this.dateAdded,
    this.autoDownload = true,
    // --- FIX: ADDED TO CONSTRUCTOR ---
    this.url,
    this.status,
    this.totalEpisodes,
  });

  factory TrackedAnime.fromJson(Map<String, dynamic> json) =>
      _$TrackedAnimeFromJson(json);

  Map<String, dynamic> toJson() => _$TrackedAnimeToJson(this);

  TrackedAnime copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? source,
    List<EpisodeInfo>? episodes,
    DateTime? lastChecked,
    DateTime? dateAdded,
    bool? autoDownload,
    // --- FIX: ADDED TO COPYWITH ---
    String? url,
    String? status,
    int? totalEpisodes,
  }) {
    return TrackedAnime(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      episodes: episodes ?? this.episodes,
      lastChecked: lastChecked ?? this.lastChecked,
      dateAdded: dateAdded ?? this.dateAdded,
      autoDownload: autoDownload ?? this.autoDownload,
      // --- FIX: ADDED HERE ---
      url: url ?? this.url,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
    );
  }
}