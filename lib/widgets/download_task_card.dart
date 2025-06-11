import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/download_task.dart';
import '../utils/theme.dart';

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const DownloadTaskCard({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.animeTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Episode ${task.episodeNumber}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar (only for active downloads)
            if (task.isActive || task.isPaused) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: task.progress / 100.0,
                      backgroundColor: _getStatusColor().withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${task.progress}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // File info and actions
            Row(
              children: [
                Icon(
                  MdiIcons.file,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.fileName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButtons(),
              ],
            ),
            
            // Error message for failed downloads
            if (task.isFailed && task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.alertCircle,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Completion time for completed downloads
            if (task.isCompleted && task.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    MdiIcons.clockOutline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed ${_formatDate(task.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        task.statusText,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    if (task.canPause && onPause != null) {
      buttons.add(
        IconButton(
          onPressed: onPause,
          icon: Icon(MdiIcons.pause),
          iconSize: 20,
          tooltip: 'Pause',
        ),
      );
    }

    if (task.canResume && onResume != null) {
      buttons.add(
        IconButton(
          onPressed: onResume,
          icon: Icon(MdiIcons.play),
          iconSize: 20,
          tooltip: 'Resume',
        ),
      );
    }

    if (task.canRetry && onRetry != null) {
      buttons.add(
        IconButton(
          onPressed: onRetry,
          icon: Icon(MdiIcons.refresh),
          iconSize: 20,
          tooltip: 'Retry',
        ),
      );
    }

    if (onCancel != null && !task.isCompleted) {
      buttons.add(
        IconButton(
          onPressed: onCancel,
          icon: Icon(MdiIcons.close),
          iconSize: 20,
          tooltip: 'Cancel',
        ),
      );
    }

    if (onDelete != null && (task.isCompleted || task.isFailed)) {
      buttons.add(
        IconButton(
          onPressed: onDelete,
          icon: Icon(MdiIcons.delete),
          iconSize: 20,
          tooltip: 'Delete',
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }

  Color _getStatusColor() {
    switch (task.status) {
      case DownloadStatus.enqueued:
        return Colors.orange;
      case DownloadStatus.running:
        return AppTheme.primaryCyan;
      case DownloadStatus.complete:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.canceled:
        return Colors.grey;
      case DownloadStatus.paused:
        return AppTheme.primaryPink;
      default:
        return Colors.grey;
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
}

