import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'services/anime_tracking_service.dart';
import 'services/download_service.dart';
import 'services/background_service.dart';
import 'services/settings_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await SettingsService().initialize();
  await AnimeTrackingService().initialize();
  await DownloadService().initialize();
  await BackgroundService().initialize();
  
  runApp(const ProviderScope(child: SenpieApp()));
}

class SenpieApp extends ConsumerWidget {
  const SenpieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Senpie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

