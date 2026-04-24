import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie_model.freezed.dart';
part 'movie_model.g.dart';

@freezed
class Movie with _$Movie {
  const factory Movie({
    required String id,
    required String title,
    required String description,
    required String posterUrl,
    required String backdropUrl,
    required List<String> genres,
    required List<String> hashtags,
    required List<Episode> episodes,
    required int totalEpisodes,
    required double rating,
  }) = _Movie;

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
}

@freezed
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String movieId,
    required int episodeNumber,
    required String title,
    required String videoUrl,
    required String thumbnailUrl,
    required Duration duration,
    required String description,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
}

@freezed
class WatchProgress with _$WatchProgress {
  const factory WatchProgress({
    required String episodeId,
    required double progress, // 0.0 to 1.0
    required Duration lastPosition,
    required DateTime lastWatched,
  }) = _WatchProgress;

  factory WatchProgress.fromJson(Map<String, dynamic> json) => _$WatchProgressFromJson(json);
}
