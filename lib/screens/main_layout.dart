import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tray_service.dart';
import '../state/app_state.dart';
import 'apps_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import 'shell_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static const _screens = [
    DevicesScreen(),
    ShellScreen(),
    AppsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDevices();
    });
    if (Platform.isMacOS || Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final appState = context.read<AppState>();
        TrayService.onOpenToSection = (int? sectionIndex) {
          if (!mounted) return;
          if (sectionIndex != null) {
            setState(() => _selectedIndex = sectionIndex);
          }
        };
        TrayService.onClearCache = (package) =>
            appState.clearPackageCache(package);
        TrayService.onClearData = (package) =>
            appState.clearPackageData(package);
        TrayService.onUninstall = (package) =>
            appState.uninstallPackage(package);
        await TrayService.setupTrayAndWindow();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.phone_android),
                label: Text('Devices'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.terminal),
                label: Text('Shell'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apps),
                label: Text('Apps'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
