import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/anime_metadata.dart';
import '../services/anime_tracking_service.dart';
import '../utils/theme.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final AnimeTrackingService _trackingService = AnimeTrackingService();
  
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _selectedSource = 'gogo';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  MdiIcons.magnify,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search Anime',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(MdiIcons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Source Selection
            Row(
              children: [
                Text(
                  'Source:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'gogo',
                        label: Text('Gogoanime'),
                        icon: Icon(Icons.play_circle),
                      ),
                      ButtonSegment(
                        value: 'pahe',
                        label: Text('Animepahe'),
                        icon: Icon(Icons.movie),
                      ),
                    ],
                    selected: {_selectedSource},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedSource = selection.first;
                        _searchResults.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter anime title...',
                prefixIcon: Icon(MdiIcons.magnify),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: _searchAnime,
                        icon: Icon(MdiIcons.arrowRight),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (_) => _searchAnime(),
            ),
            const SizedBox(height: 16),
            
            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching anime...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.magnify,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for anime',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an anime title and select a source to start searching',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                MdiIcons.television,
                color: AppTheme.primaryPurple,
              ),
            ),
            title: Text(
              result.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getSourceColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedSource.toUpperCase(),
                style: TextStyle(
                  color: _getSourceColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing: IconButton(
              onPressed: () => _addAnimeToLibrary(result),
              icon: Icon(
                MdiIcons.plus,
                color: AppTheme.primaryPurple,
              ),
            ),
            onTap: () => _addAnimeToLibrary(result),
          ),
        );
      },
    );
  }

  Color _getSourceColor() {
    switch (_selectedSource) {
      case 'gogo':
        return AppTheme.primaryCyan;
      case 'pahe':
        return AppTheme.primaryPink;
      default:
        return AppTheme.primaryPurple;
    }
  }

  Future<void> _searchAnime() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      final results = await _trackingService.searchAnime(query, _selectedSource);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _addAnimeToLibrary(SearchResult result) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding anime to library...'),
            ],
          ),
        ),
      );

      // Get anime metadata
      final metadata = await _trackingService.getAnimeMetadata(result.url, _selectedSource);
      
      // Add to tracking
      await _trackingService.addAnimeToTracking(metadata, _selectedSource);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Close search dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.title} added to library'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add anime: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

