import 'dart:convert';

enum DownloadStatus {
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused,
}

class DownloadTask {
  final String id;
  final String animeId;
  final String animeTitle;
  final int episodeNumber;
  final String fileName;
  final String downloadPath;
  final DownloadStatus status;
  final int progress;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const DownloadTask({
    required this.id,
    required this.animeId,
    required this.animeTitle,
    required this.episodeNumber,
    required this.fileName,
    required this.downloadPath,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory DownloadTask.empty() {
    return DownloadTask(
      id: '',
      animeId: '',
      animeTitle: '',
      episodeNumber: 0,
      fileName: '',
      downloadPath: '',
      status: DownloadStatus.undefined,
      progress: 0,
      createdAt: DateTime.now(),
    );
  }

  factory DownloadTask.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DownloadTask(
      id: json['id'] as String,
      animeId: json['animeId'] as String,
      animeTitle: json['animeTitle'] as String,
      episodeNumber: json['episodeNumber'] as int,
      fileName: json['fileName'] as String,
      downloadPath: json['downloadPath'] as String,
      status: DownloadStatus.values[json['status'] as int],
      progress: json['progress'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  String toJson() {
    final json = {
      'id': id,
      'animeId': animeId,
      'animeTitle': animeTitle,
      'episodeNumber': episodeNumber,
      'fileName': fileName,
      'downloadPath': downloadPath,
      'status': status.index,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
    return jsonEncode(json);
  }

  DownloadTask copyWith({
    String? id,
    String? animeId,
    String? animeTitle,
    int? episodeNumber,
    String? fileName,
    String? downloadPath,
    DownloadStatus? status,
    int? progress,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      fileName: fileName ?? this.fileName,
      downloadPath: downloadPath ?? this.downloadPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get displayTitle => '$animeTitle - Episode $episodeNumber';

  String get statusText {
    switch (status) {
      case DownloadStatus.undefined:
        return 'Unknown';
      case DownloadStatus.enqueued:
        return 'Queued';
      case DownloadStatus.running:
        return 'Downloading';
      case DownloadStatus.complete:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.canceled:
        return 'Canceled';
      case DownloadStatus.paused:
        return 'Paused';
    }
  }

  bool get isActive => 
      status == DownloadStatus.running || 
      status == DownloadStatus.enqueued;

  bool get isPaused => status == DownloadStatus.paused;

  bool get isCompleted => status == DownloadStatus.complete;

  bool get isFailed => status == DownloadStatus.failed;

  bool get canPause => status == DownloadStatus.running;

  bool get canResume => status == DownloadStatus.paused;

  bool get canRetry => 
      status == DownloadStatus.failed || 
      status == DownloadStatus.canceled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DownloadTask{id: $id, animeTitle: $animeTitle, episodeNumber: $episodeNumber, status: $status, progress: $progress}';
  }
}

