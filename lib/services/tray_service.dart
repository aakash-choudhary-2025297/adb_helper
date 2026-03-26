import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Apps-focused tray + window behaviour (PRD §8).
/// - System tray menu: Open, list of apps (from device), Open Apps…, Quit
/// - Close window → hide to tray (background), not quit
class TrayService {
  TrayService._();

  static bool _initialized = false;
  static bool _closeListenerAdded = false;
  static final _TrayClickListener _trayClickListener = _TrayClickListener();

  /// Callback when tray requests "Open Apps" (or other section): (sectionIndex) => show window + switch tab.
  static void Function(int? sectionIndex)? onOpenToSection;

  /// Callbacks for per-app tray actions.
  static Future<bool> Function(String package)? onClearCache;
  static Future<bool> Function(String package)? onClearData;
  static Future<bool> Function(String package)? onUninstall;

  static const int sectionApps = 2;

  /// Max app names shown in the tray menu (rest: "Open Apps for more…").
  static const int _maxTrayApps = 30;

  static List<String> _packages = [];

  /// Updates the tray menu with the current app list. Call when packages are loaded (e.g. from AppState).
  static Future<void> updateMenu(List<String> packages) async {
    if (!_initialized) return;
    _packages = List.from(packages);
    await trayManager.setContextMenu(_buildMenu());
  }

  static Future<void> init() async {
    if (_initialized) return;
    await windowManager.ensureInitialized();
    _initialized = true;
  }

  /// Call after [WindowManager.ensureInitialized]. Sets up tray icon + menu and close-to-hide.
  static Future<void> setupTrayAndWindow() async {
    await init();

    // Close → hide to tray instead of quitting
    windowManager.setPreventClose(true);
    if (!_closeListenerAdded) {
      windowManager.addListener(_WindowCloseListener());
      _closeListenerAdded = true;
    }

    // Tray icon + menu (Apps-focused)
    final iconPath = Platform.isWindows
        ? 'assets/images/app_icon_tray.ico'
        : 'assets/images/app_icon_tray.png';
    try {
      await trayManager.setIcon(iconPath);
    } catch (_) {
      debugPrint('TrayService: setIcon failed (add app_icon_tray.ico on Windows)');
    }
    await trayManager.setToolTip('ADB Helper');
    await trayManager.setContextMenu(_buildMenu());
    trayManager.addListener(_trayClickListener);
  }

  static String _displayName(String package) {
    final last = package.split('.').last;
    if (last.isEmpty) return package;
    final first = last.split('_').first;
    if (first.isEmpty) return last;
    return first.length == 1
        ? first.toUpperCase()
        : '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
  }

  static Menu _buildMenu() {
    final items = <MenuItem>[
      MenuItem(
        label: 'Open ADB Helper',
        onClick: (MenuItem item) async {
          onOpenToSection?.call(sectionApps);
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItem.separator(),
    ];

    if (_packages.isEmpty) {
      items.add(
        MenuItem(
          label: 'Open Apps',
          onClick: (MenuItem item) async {
            onOpenToSection?.call(sectionApps);
            await windowManager.show();
            await windowManager.focus();
          },
        ),
      );
    } else {
      final showCount = _packages.length > _maxTrayApps ? _maxTrayApps : _packages.length;
      for (var i = 0; i < showCount; i++) {
        final package = _packages[i];
        final label = _displayName(package);
        final displayLabel = label.length > 40 ? '${label.substring(0, 37)}…' : label;
        items.add(
          MenuItem.submenu(
            label: displayLabel,
            submenu: Menu(items: [
              MenuItem(
                label: 'Clear Cache',
                onClick: (MenuItem item) async {
                  onClearCache?.call(package);
                },
              ),
              MenuItem(
                label: 'Clear Data',
                onClick: (MenuItem item) async {
                  onClearData?.call(package);
                },
              ),
              MenuItem(
                label: 'Uninstall',
                onClick: (MenuItem item) async {
                  onUninstall?.call(package);
                },
              ),
            ]),
          ),
        );
      }
      if (_packages.length > _maxTrayApps) {
        items.add(
          MenuItem(
            label: 'Open Apps for more…',
            onClick: (MenuItem item) async {
              onOpenToSection?.call(sectionApps);
              await windowManager.show();
              await windowManager.focus();
            },
          ),
        );
      }
    }

    items.add(MenuItem.separator());
    items.add(
      MenuItem(
        label: 'Quit',
        onClick: (MenuItem item) async {
          await trayManager.destroy();
          await windowManager.destroy();
        },
      ),
    );

    return Menu(items: items);
  }

  static Future<void> destroy() async {
    trayManager.removeListener(_trayClickListener);
    await trayManager.destroy();
    _initialized = false;
  }
}

/// Shows the context menu when the tray icon is clicked (left or right).
class _TrayClickListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }
}

class _WindowCloseListener extends WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}
