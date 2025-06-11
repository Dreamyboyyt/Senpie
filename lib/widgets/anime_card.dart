import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/anime_metadata.dart';
import '../utils/theme.dart';
import '../screens/anime_detail_screen.dart';

class AnimeCard extends StatelessWidget {
  final TrackedAnime anime;

  const AnimeCard({
    super.key,
    required this.anime,
  });

  @override
  Widget build(BuildContext context) {
    final totalEpisodes = anime.episodes.length;
    final downloadedEpisodes = anime.episodes.where((ep) => ep.isDownloaded).length;
    final watchedEpisodes = anime.episodes.where((ep) => ep.isWatched).length;
    final downloadProgress = totalEpisodes > 0 ? downloadedEpisodes / totalEpisodes : 0.0;
    final watchProgress = totalEpisodes > 0 ? watchedEpisodes / totalEpisodes : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anime Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                ),
                child: anime.imageUrl.isNotEmpty
                    ? Image.network(
                        anime.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            // Anime Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      anime.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSourceColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        anime.source.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getSourceColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Progress indicators
                    Column(
                      children: [
                        _buildProgressIndicator(
                          context,
                          'Downloaded',
                          downloadProgress,
                          downloadedEpisodes,
                          totalEpisodes,
                          AppTheme.primaryCyan,
                          MdiIcons.download,
                        ),
                        const SizedBox(height: 4),
                        _buildProgressIndicator(
                          context,
                          'Watched',
                          watchProgress,
                          watchedEpisodes,
                          totalEpisodes,
                          AppTheme.primaryPink,
                          MdiIcons.eye,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
      ),
      child: Icon(
        MdiIcons.television,
        size: 48,
        color: AppTheme.primaryPurple.withOpacity(0.5),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    double progress,
    int current,
    int total,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$current/$total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSourceColor() {
    switch (anime.source.toLowerCase()) {
      case 'gogo':
        return AppTheme.primaryCyan;
      case 'pahe':
        return AppTheme.primaryPink;
      default:
        return AppTheme.primaryPurple;
    }
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnimeDetailScreen(anime: anime),
      ),
    );
  }
}

