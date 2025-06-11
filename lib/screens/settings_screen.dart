import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/settings_service.dart';
import '../services/library_service.dart';
import '../services/background_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final SettingsService _settingsService = SettingsService();

  SettingsNotifier() : super({}) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = _settingsService.getAllSettings();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    switch (key) {
      case AppConstants.keyVideoQuality:
        await _settingsService.setVideoQuality(value);
        break;
      case AppConstants.keyLanguage:
        await _settingsService.setLanguage(value);
        break;
      case AppConstants.keyAutoDownload:
        await _settingsService.setAutoDownload(value);
        break;
      case AppConstants.keyWifiOnly:
        await _settingsService.setWifiOnly(value);
        break;
      case AppConstants.keyCheckInterval:
        await _settingsService.setCheckInterval(value);
        await BackgroundService().updateCheckInterval(value);
        break;
      case AppConstants.keyTheme:
        await _settingsService.setTheme(value);
        break;
      case AppConstants.keyNotificationsEnabled:
        await _settingsService.setNotificationsEnabled(value);
        break;
      case AppConstants.keyDownloadNotifications:
        await _settingsService.setDownloadNotifications(value);
        break;
      case AppConstants.keyEpisodeNotifications:
        await _settingsService.setEpisodeNotifications(value);
        break;
    }
    await _loadSettings();
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final LibraryService _libraryService = LibraryService();
  
  Map<String, dynamic>? _storageInfo;
  bool _isLoadingStorage = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoadingStorage = true);
    try {
      final info = await _settingsService.getStorageInfo();
      setState(() => _storageInfo = info);
    } catch (e) {
      print('Failed to load storage info: $e');
    } finally {
      setState(() => _isLoadingStorage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(MdiIcons.restore, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Download Settings'),
          _buildSettingsCard([
            _buildQualitySelector(settings, settingsNotifier),
            _buildLanguageSelector(settings, settingsNotifier),
            _buildDownloadPathSelector(),
            _buildSwitchTile(
              'Auto Download',
              'Automatically download new episodes',
              MdiIcons.downloadMultiple,
              settings['autoDownload'] ?? true,
              (value) => settingsNotifier.updateSetting(AppConstants.keyAutoDownload, value),
            ),
            _buildSwitchTile(
              'WiFi Only',
              'Only download when connected to WiFi',
              MdiIcons.wifi,
              settings['wifiOnly'] ?? true,
              (value) => settingsNotifier.updateSetting(AppConstants.keyWifiOnly, value),
            ),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Episode Checking'),
          _buildSettingsCard([
            _buildCheckIntervalSelector(settings, settingsNotifier),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Enable Notifications',
              'Receive notifications from the app',
              MdiIcons.bell,
              settings['notificationsEnabled'] ?? true,
              (value) => settingsNotifier.updateSetting(AppConstants.keyNotificationsEnabled, value),
            ),
            _buildSwitchTile(
              'Download Notifications',
              'Notify when downloads complete',
              MdiIcons.downloadCircle,
              settings['downloadNotifications'] ?? true,
              (value) => settingsNotifier.updateSetting(AppConstants.keyDownloadNotifications, value),
            ),
            _buildSwitchTile(
              'Episode Notifications',
              'Notify when new episodes are available',
              MdiIcons.televisionPlay,
              settings['episodeNotifications'] ?? true,
              (value) => settingsNotifier.updateSetting(AppConstants.keyEpisodeNotifications, value),
            ),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            _buildThemeSelector(settings, settingsNotifier),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Storage'),
          _buildSettingsCard([
            _buildStorageInfo(),
            _buildActionTile(
              'Clear Cache',
              'Free up space by clearing cached data',
              MdiIcons.broom,
              _clearCache,
            ),
          ]),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Library'),
          _buildSettingsCard([
            _buildActionTile(
              'Export Library',
              'Backup your anime library and settings',
              MdiIcons.export,
              _exportLibrary,
            ),
            _buildActionTile(
              'Import Library',
              'Restore your anime library from backup',
              MdiIcons.import,
              _importLibrary,
            ),
            _buildActionTile(
              'Share Library',
              'Share your library with others',
              MdiIcons.share,
              _shareLibrary,
            ),
            _buildActionTile(
              'Cleanup Library',
              'Remove empty or outdated entries',
              MdiIcons.autoFix,
              _cleanupLibrary,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children
            .expand((widget) => [widget, const Divider(height: 1)])
            .take(children.length * 2 - 1)
            .toList(),
      ),
    );
  }

  Widget _buildQualitySelector(Map<String, dynamic> settings, SettingsNotifier notifier) {
    final currentQuality = settings['videoQuality'] ?? AppConstants.defaultQuality;
    
    return ListTile(
      leading: Icon(MdiIcons.qualityHigh, color: AppTheme.primaryPurple),
      title: const Text('Video Quality'),
      subtitle: Text('Current: $currentQuality'),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: () => _showQualityDialog(currentQuality, notifier),
    );
  }

  Widget _buildLanguageSelector(Map<String, dynamic> settings, SettingsNotifier notifier) {
    final currentLanguage = settings['language'] ?? AppConstants.defaultLanguage;
    
    return ListTile(
      leading: Icon(MdiIcons.translate, color: AppTheme.primaryPurple),
      title: const Text('Language'),
      subtitle: Text('Current: ${currentLanguage.toUpperCase()}'),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: () => _showLanguageDialog(currentLanguage, notifier),
    );
  }

  Widget _buildDownloadPathSelector() {
    return ListTile(
      leading: Icon(MdiIcons.folder, color: AppTheme.primaryPurple),
      title: const Text('Download Path'),
      subtitle: Text(_settingsService.downloadPath),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: _selectDownloadPath,
    );
  }

  Widget _buildCheckIntervalSelector(Map<String, dynamic> settings, SettingsNotifier notifier) {
    final currentInterval = Duration(minutes: settings['checkInterval'] ?? 60);
    
    return ListTile(
      leading: Icon(MdiIcons.clockOutline, color: AppTheme.primaryPurple),
      title: const Text('Check Interval'),
      subtitle: Text('Check for new episodes every ${_formatDuration(currentInterval)}'),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: () => _showIntervalDialog(currentInterval, notifier),
    );
  }

  Widget _buildThemeSelector(Map<String, dynamic> settings, SettingsNotifier notifier) {
    final currentTheme = settings['theme'] ?? 'system';
    
    return ListTile(
      leading: Icon(MdiIcons.palette, color: AppTheme.primaryPurple),
      title: const Text('Theme'),
      subtitle: Text('Current: ${_capitalizeFirst(currentTheme)}'),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: () => _showThemeDialog(currentTheme, notifier),
    );
  }

  Widget _buildStorageInfo() {
    if (_isLoadingStorage) {
      return ListTile(
        leading: Icon(MdiIcons.harddisk, color: AppTheme.primaryPurple),
        title: const Text('Storage Used'),
        subtitle: const Text('Calculating...'),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final totalSize = _storageInfo?['totalSize'] ?? 0;
    final fileCount = _storageInfo?['fileCount'] ?? 0;
    
    return ListTile(
      leading: Icon(MdiIcons.harddisk, color: AppTheme.primaryPurple),
      title: const Text('Storage Used'),
      subtitle: Text('$fileCount files'),
      trailing: Text(_settingsService.formatFileSize(totalSize)),
      onTap: _loadStorageInfo,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryPurple,
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPurple),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(MdiIcons.chevronRight),
      onTap: onTap,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showQualityDialog(String currentQuality, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Video Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.videoQualities.map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: currentQuality,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSetting(AppConstants.keyVideoQuality, value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPurple,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(String currentLanguage, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['sub', 'dub'].map((language) {
            return RadioListTile<String>(
              title: Text(language.toUpperCase()),
              value: language,
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSetting(AppConstants.keyLanguage, value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPurple,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showIntervalDialog(Duration currentInterval, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.checkIntervals.map((interval) {
            return RadioListTile<Duration>(
              title: Text(_formatDuration(interval)),
              value: interval,
              groupValue: currentInterval,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSetting(AppConstants.keyCheckInterval, value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPurple,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(String currentTheme, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['light', 'dark', 'system'].map((theme) {
            return RadioListTile<String>(
              title: Text(_capitalizeFirst(theme)),
              value: theme,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSetting(AppConstants.keyTheme, value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPurple,
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectDownloadPath() async {
    try {
      final path = await _settingsService.selectDownloadPath();
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download path updated: $path'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        await _loadStorageInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select download path: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _settingsService.clearCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully'),
              backgroundColor: AppTheme.primaryPurple,
            ),
          );
          await _loadStorageInfo();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportLibrary() async {
    try {
      final exportPath = await _libraryService.exportLibrary();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Library exported to: $exportPath'),
            backgroundColor: AppTheme.primaryPurple,
            action: SnackBarAction(
              label: 'Share',
              onPressed: _shareLibrary,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export library: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importLibrary() async {
    try {
      final filePath = await _libraryService.selectImportFile();
      if (filePath != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Library'),
            content: const Text('This will merge the imported data with your current library. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _libraryService.importLibrary(filePath);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Library imported successfully'),
                backgroundColor: AppTheme.primaryPurple,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import library: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareLibrary() async {
    try {
      await _libraryService.shareLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share library: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cleanupLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Library'),
        content: const Text('This will remove anime with no episodes that haven\'t been updated in 30 days. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _libraryService.cleanupLibrary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Library cleaned up successfully'),
              backgroundColor: AppTheme.primaryPurple,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cleanup library: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _resetToDefaults();
        break;
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _settingsService.resetToDefaults();
        ref.read(settingsProvider.notifier)._loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to defaults'),
              backgroundColor: AppTheme.primaryPurple,
            ),
          );
          await _loadStorageInfo();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset settings: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

