class AppConstants {
  // App Information
  static const String appName = 'Senpie';
  static const String appVersion = '1.0.0';
  static const String packageName = 'dev.sleepy.senpie';

  // Default Settings
  static const String defaultDownloadPath = '/storage/emulated/0/Download/';
  static const String defaultQuality = '720p';
  static const String defaultLanguage = 'sub';
  static const Duration defaultCheckInterval = Duration(hours: 1);

  // Supported Video Qualities
  static const List<String> videoQualities = [
    '360p',
    '480p',
    '720p',
    '1080p',
  ];

  // Check Intervals
  static const List<Duration> checkIntervals = [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 6),
  ];

  // Theme Settings
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String systemTheme = 'system';

  // Database
  static const String databaseName = 'senpie.db';
  static const int databaseVersion = 1;

  // Notification Channels
  static const String downloadChannelId = 'download_channel';
  static const String episodeChannelId = 'episode_channel';

  // SharedPreferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAutoDownload = 'auto_download';
  static const String keyDownloadPath = 'download_path';
  static const String keyVideoQuality = 'video_quality';
  static const String keyLanguageMode = 'language_mode';
  static const String keyLanguage = 'language';
  static const String keyCheckInterval = 'check_interval';
  static const String keyWifiOnly = 'wifi_only';
  static const String keyFirstRun = 'first_run';
  static const String keyTheme = 'theme';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDownloadNotifications = 'download_notifications';
  static const String keyEpisodeNotifications = 'episode_notifications';

  // Work Manager
  static const String episodeCheckTaskName = 'episode_check_task';
  static const String downloadTaskName = 'download_task';
}

class GogoConstants {
  static const String siteName = 'Gogoanime';
  static const String baseUrl = 'https://anitaku.bz';
  static const String searchUrl = '$baseUrl/search.html';
  static const String ajaxSearchUrl = '$baseUrl/filter.html';
  static const String ajaxLoadEpsUrl = '$baseUrl/load-list-episode';
  static const String dubExtension = ' (Dub)';
  
  // Regex patterns
  static const String baseUrlRegex = r'https://anitaku\.[a-z]+';
}

class PaheConstants {
  static const String siteName = 'Animepahe';
  static const String baseUrl = 'https://animepahe.ru';
  static const String apiEntryPoint = '$baseUrl/api?m=';
  static const String animePageUrl = '$baseUrl/anime/';
  static const String loadEpisodesUrl = '$baseUrl/api?m=release&id=';
  static const String episodePageUrl = '$baseUrl/play/';
  
  // Regex patterns
  static const String baseUrlRegex = r'https://animepahe\.[a-z]+';
  static const String dubPattern = r'\(Dub\)';
  static const String episodeSizeRegex = r'(\d+(?:\.\d+)?)\s*(MB|GB)';
  static const String kwikPageRegex = r'https://kwik\.si/[^"]+';
  static const String paramRegex = r'eval\(function\(p,a,c,k,e,d\).*?\)\)';
}

class ErrorMessages {
  static const String networkError = 'Network error occurred. Please check your internet connection.';
  static const String scrapingError = 'Failed to scrape data from the website.';
  static const String downloadError = 'Failed to download the episode.';
  static const String permissionError = 'Storage permission is required to download files.';
  static const String noEpisodesFound = 'No episodes found for this anime.';
  static const String animeNotFound = 'Anime not found.';
  static const String invalidUrl = 'Invalid URL provided.';
}

