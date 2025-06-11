import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/anime_metadata.dart';
import '../utils/theme.dart';
import '../services/anime_tracking_service.dart';

class AnimeDetailScreen extends StatefulWidget {
  final TrackedAnime anime;

  const AnimeDetailScreen({
    super.key,
    required this.anime,
  });

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final AnimeTrackingService _trackingService = AnimeTrackingService();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimeInfo(),
                  const SizedBox(height: 24),
                  _buildEpisodesList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.anime.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.anime.imageUrl.isNotEmpty
                ? Image.network(
                    widget.anime.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(MdiIcons.refresh),
          onPressed: _isUpdating ? null : _updateAnime,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(MdiIcons.delete, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Text('Remove from Library'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
      ),
      child: Icon(
        MdiIcons.television,
        size: 80,
        color: AppTheme.primaryPurple.withOpacity(0.5),
      ),
    );
  }

  Widget _buildAnimeInfo() {
    final totalEpisodes = widget.anime.episodes.length;
    final downloadedEpisodes = widget.anime.episodes.where((ep) => ep.isDownloaded).length;
    final watchedEpisodes = widget.anime.episodes.where((ep) => ep.isWatched).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSourceColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.anime.source.toUpperCase(),
                    style: TextStyle(
                      color: _getSourceColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Last checked: ${_formatDate(widget.anime.lastChecked)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Episodes',
                    totalEpisodes.toString(),
                    MdiIcons.playCircle,
                    AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Downloaded',
                    downloadedEpisodes.toString(),
                    MdiIcons.download,
                    AppTheme.primaryCyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Watched',
                    watchedEpisodes.toString(),
                    MdiIcons.eye,
                    AppTheme.primaryPink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Episodes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _downloadAllEpisodes,
              icon: Icon(MdiIcons.downloadMultiple),
              label: const Text('Download All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.anime.episodes.length,
          itemBuilder: (context, index) {
            final episode = widget.anime.episodes[index];
            return _buildEpisodeCard(episode);
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeCard(EpisodeInfo episode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: episode.isDownloaded
              ? AppTheme.primaryCyan.withOpacity(0.2)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          child: Text(
            episode.episodeNumber.toString(),
            style: TextStyle(
              color: episode.isDownloaded
                  ? AppTheme.primaryCyan
                  : Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text('Episode ${episode.episodeNumber}'),
        subtitle: Row(
          children: [
            if (episode.isDownloaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Downloaded',
                  style: TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (episode.isWatched)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Watched',
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleEpisodeAction(action, episode),
          itemBuilder: (context) => [
            if (!episode.isDownloaded)
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(MdiIcons.download),
                    const SizedBox(width: 8),
                    const Text('Download'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: episode.isWatched ? 'unwatched' : 'watched',
              child: Row(
                children: [
                  Icon(episode.isWatched ? MdiIcons.eyeOff : MdiIcons.eye),
                  const SizedBox(width: 8),
                  Text(episode.isWatched ? 'Mark Unwatched' : 'Mark Watched'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor() {
    switch (widget.anime.source.toLowerCase()) {
      case 'gogo':
        return AppTheme.primaryCyan;
      case 'pahe':
        return AppTheme.primaryPink;
      default:
        return AppTheme.primaryPurple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _updateAnime() async {
    setState(() => _isUpdating = true);
    
    try {
      await _trackingService.updateAnimeEpisodes(widget.anime.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anime updated successfully'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update anime: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'remove':
        _showRemoveDialog();
        break;
    }
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Anime'),
        content: Text('Are you sure you want to remove "${widget.anime.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _trackingService.removeAnimeFromTracking(widget.anime.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anime removed from library'),
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleEpisodeAction(String action, EpisodeInfo episode) {
    switch (action) {
      case 'download':
        _downloadEpisode(episode);
        break;
      case 'watched':
        _trackingService.markEpisodeAsWatched(widget.anime.id, episode.episodeNumber);
        break;
      case 'unwatched':
        // TODO: Implement mark as unwatched
        break;
    }
  }

  void _downloadEpisode(EpisodeInfo episode) {
    // TODO: Implement episode download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading Episode ${episode.episodeNumber}...'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  void _downloadAllEpisodes() {
    // TODO: Implement download all episodes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download all episodes feature coming soon'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }
}

