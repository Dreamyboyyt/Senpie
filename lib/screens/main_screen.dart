import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import 'credits_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const DownloadsScreen(),
    const SettingsScreen(),
    const CreditsScreen(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: Icon(MdiIcons.bookshelf),
      activeIcon: Icon(MdiIcons.bookshelf),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: Icon(MdiIcons.download),
      activeIcon: Icon(MdiIcons.download),
      label: 'Downloads',
    ),
    BottomNavigationBarItem(
      icon: Icon(MdiIcons.cog),
      activeIcon: Icon(MdiIcons.cog),
      label: 'Settings',
    ),
    BottomNavigationBarItem(
      icon: Icon(MdiIcons.information),
      activeIcon: Icon(MdiIcons.information),
      label: 'Credits',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navigationItems,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}

