import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/download_task.dart';
import '../services/download_service.dart';
import '../widgets/download_task_card.dart';
import '../utils/theme.dart';

final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  return DownloadService().downloadTasksStream;
});

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadTasksAsync = ref.watch(downloadTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: Icon(MdiIcons.pause),
            onPressed: _pauseAllDownloads,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(MdiIcons.broom),
                    const SizedBox(width: 8),
                    const Text('Clear Completed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'retry_failed',
                child: Row(
                  children: [
                    Icon(MdiIcons.refresh),
                    const SizedBox(width: 8),
                    const Text('Retry Failed'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(MdiIcons.download),
              text: 'Active',
            ),
            Tab(
              icon: Icon(MdiIcons.pause),
              text: 'Paused',
            ),
            Tab(
              icon: Icon(MdiIcons.checkCircle),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: downloadTasksAsync.when(
        data: (allTasks) => TabBarView(
          controller: _tabController,
          children: [
            _buildActiveDownloads(allTasks),
            _buildPausedDownloads(allTasks),
            _buildCompletedDownloads(allTasks),
          ],
        ),
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
                'Error loading downloads',
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
    );
  }

  Widget _buildActiveDownloads(List<DownloadTask> allTasks) {
    final activeTasks = allTasks.where((task) => task.isActive).toList();
    
    if (activeTasks.isEmpty) {
      return _buildEmptyState(
        'No Active Downloads',
        'Downloads will appear here when episodes are being downloaded',
        MdiIcons.download,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTasks.length,
      itemBuilder: (context, index) {
        return DownloadTaskCard(
          task: activeTasks[index],
          onPause: () => _pauseDownload(activeTasks[index].id),
          onCancel: () => _cancelDownload(activeTasks[index].id),
        );
      },
    );
  }

  Widget _buildPausedDownloads(List<DownloadTask> allTasks) {
    final pausedTasks = allTasks.where((task) => task.isPaused).toList();
    
    if (pausedTasks.isEmpty) {
      return _buildEmptyState(
        'No Paused Downloads',
        'Paused downloads will appear here',
        MdiIcons.pause,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pausedTasks.length,
      itemBuilder: (context, index) {
        return DownloadTaskCard(
          task: pausedTasks[index],
          onResume: () => _resumeDownload(pausedTasks[index].id),
          onCancel: () => _cancelDownload(pausedTasks[index].id),
        );
      },
    );
  }

  Widget _buildCompletedDownloads(List<DownloadTask> allTasks) {
    final completedTasks = allTasks.where((task) => 
      task.isCompleted || task.isFailed
    ).toList();
    
    if (completedTasks.isEmpty) {
      return _buildEmptyState(
        'No Completed Downloads',
        'Successfully downloaded episodes will appear here',
        MdiIcons.checkCircle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTasks.length,
      itemBuilder: (context, index) {
        final task = completedTasks[index];
        return DownloadTaskCard(
          task: task,
          onRetry: task.isFailed ? () => _retryDownload(task.id) : null,
          onDelete: () => _deleteDownload(task.id),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
                icon,
                size: 60,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pauseDownload(String taskId) async {
    try {
      await _downloadService.pauseDownload(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause download: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _resumeDownload(String taskId) async {
    try {
      await _downloadService.resumeDownload(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume download: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelDownload(String taskId) async {
    try {
      await _downloadService.cancelDownload(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel download: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _retryDownload(String taskId) async {
    try {
      await _downloadService.retryDownload(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry download: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDownload(String taskId) async {
    try {
      await _downloadService.cancelDownload(taskId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete download: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pauseAllDownloads() async {
    final allTasks = _downloadService.downloadTasks;
    final activeTasks = allTasks.where((task) => task.isActive).toList();
    
    for (final task in activeTasks) {
      try {
        await _downloadService.pauseDownload(task.id);
      } catch (e) {
        print('Failed to pause download ${task.id}: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All downloads paused'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_completed':
        _clearCompletedDownloads();
        break;
      case 'retry_failed':
        _retryFailedDownloads();
        break;
    }
  }

  Future<void> _clearCompletedDownloads() async {
    final allTasks = _downloadService.downloadTasks;
    final completedTasks = allTasks.where((task) => task.isCompleted).toList();
    
    for (final task in completedTasks) {
      try {
        await _downloadService.cancelDownload(task.id);
      } catch (e) {
        print('Failed to clear completed download ${task.id}: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed downloads cleared'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }

  Future<void> _retryFailedDownloads() async {
    final allTasks = _downloadService.downloadTasks;
    final failedTasks = allTasks.where((task) => task.isFailed).toList();
    
    for (final task in failedTasks) {
      try {
        await _downloadService.retryDownload(task.id);
      } catch (e) {
        print('Failed to retry download ${task.id}: $e');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed downloads retried'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }
}

