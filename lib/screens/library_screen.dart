import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/anime_metadata.dart';
import '../services/anime_tracking_service.dart';
import '../widgets/anime_card.dart';
import '../widgets/search_dialog.dart';
import '../utils/theme.dart';

final animeTrackingProvider = StreamProvider<List<TrackedAnime>>((ref) {
  return AnimeTrackingService().trackedAnimeStream;
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedAnimeAsync = ref.watch(animeTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/senpie_logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'Senpie',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(MdiIcons.magnify),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: Icon(MdiIcons.refresh),
            onPressed: () => _refreshAllAnime(context),
          ),
        ],
      ),
      body: trackedAnimeAsync.when(
        data: (trackedAnime) => _buildLibraryContent(context, trackedAnime),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.alertCircle,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading library',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSearchDialog(context),
        child: Icon(MdiIcons.plus),
      ),
    );
  }

  Widget _buildLibraryContent(BuildContext context, List<TrackedAnime> trackedAnime) {
    if (trackedAnime.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => _refreshAllAnime(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(context, trackedAnime),
            const SizedBox(height: 16),
            Text(
              'Your Anime Library',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: trackedAnime.length,
                itemBuilder: (context, index) {
                  return AnimeCard(anime: trackedAnime[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                MdiIcons.bookshelf,
                size: 60,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Library is Empty',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your favorite anime by searching and adding them to your library.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSearchDialog(context),
              icon: Icon(MdiIcons.magnify),
              label: const Text('Search Anime'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, List<TrackedAnime> trackedAnime) {
    final totalAnime = trackedAnime.length;
    final totalEpisodes = trackedAnime.fold<int>(
      0,
      (sum, anime) => sum + anime.episodes.length,
    );
    final downloadedEpisodes = trackedAnime.fold<int>(
      0,
      (sum, anime) => sum + anime.episodes.where((ep) => ep.isDownloaded).length,
    );
    final watchedEpisodes = trackedAnime.fold<int>(
      0,
      (sum, anime) => sum + anime.episodes.where((ep) => ep.isWatched).length,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library Stats',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Anime',
                  totalAnime.toString(),
                  MdiIcons.television,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Episodes',
                  totalEpisodes.toString(),
                  MdiIcons.playCircle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Downloaded',
                  downloadedEpisodes.toString(),
                  MdiIcons.download,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Watched',
                  watchedEpisodes.toString(),
                  MdiIcons.eye,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryPurple,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SearchDialog(),
    );
  }

  Future<void> _refreshAllAnime(BuildContext context) async {
    try {
      await AnimeTrackingService().checkAllAnimeForUpdates();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library updated successfully'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update library: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

