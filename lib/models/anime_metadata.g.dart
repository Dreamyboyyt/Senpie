// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnimeMetadata _$AnimeMetadataFromJson(Map<String, dynamic> json) =>
    AnimeMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      description: json['description'] as String,
      airingStatus: $enumDecode(_$AiringStatusEnumMap, json['airingStatus']),
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      startEpisode: (json['startEpisode'] as num).toInt(),
      endEpisode: (json['endEpisode'] as num).toInt(),
      recommendedAnime: (json['recommendedAnime'] as List<dynamic>)
          .map((e) => RecommendedAnime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnimeMetadataToJson(AnimeMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
      'description': instance.description,
      'airingStatus': _$AiringStatusEnumMap[instance.airingStatus]!,
      'genres': instance.genres,
      'startEpisode': instance.startEpisode,
      'endEpisode': instance.endEpisode,
      'recommendedAnime': instance.recommendedAnime,
    };

const _$AiringStatusEnumMap = {
  AiringStatus.ongoing: 'Ongoing',
  AiringStatus.completed: 'Completed',
};

RecommendedAnime _$RecommendedAnimeFromJson(Map<String, dynamic> json) =>
    RecommendedAnime(
      title: json['title'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$RecommendedAnimeToJson(RecommendedAnime instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
    };

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) => SearchResult(
      title: json['title'] as String,
      url: json['url'] as String,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'id': instance.id,
    };

EpisodeInfo _$EpisodeInfoFromJson(Map<String, dynamic> json) => EpisodeInfo(
      episodeNumber: (json['episodeNumber'] as num).toInt(),
      downloadUrl: json['downloadUrl'] as String,
      quality: json['quality'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isWatched: json['isWatched'] as bool? ?? false,
    );

Map<String, dynamic> _$EpisodeInfoToJson(EpisodeInfo instance) =>
    <String, dynamic>{
      'episodeNumber': instance.episodeNumber,
      'downloadUrl': instance.downloadUrl,
      'quality': instance.quality,
      'fileSize': instance.fileSize,
      'isDownloaded': instance.isDownloaded,
      'isWatched': instance.isWatched,
    };

TrackedAnime _$TrackedAnimeFromJson(Map<String, dynamic> json) => TrackedAnime(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      source: json['source'] as String,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => EpisodeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastChecked: DateTime.parse(json['lastChecked'] as String),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      autoDownload: json['autoDownload'] as bool? ?? true,
    );

Map<String, dynamic> _$TrackedAnimeToJson(TrackedAnime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'source': instance.source,
      'episodes': instance.episodes,
      'lastChecked': instance.lastChecked.toIso8601String(),
      'dateAdded': instance.dateAdded.toIso8601String(),
      'autoDownload': instance.autoDownload,
    };
