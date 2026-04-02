import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/device.dart';

/// Tray menu structure:
/// - Devices  → submenu listing connected devices (tap to select)
/// - Apps     → submenu listing packages (each with Clear Cache / Clear Data / Uninstall)
/// - Refresh  → reloads devices + packages
/// - separator
/// - Open ADB Helper
/// - Quit
class TrayService {
  TrayService._();

  static bool _initialized = false;
  static bool _closeListenerAdded = false;
  static final _TrayClickListener _trayClickListener = _TrayClickListener();

  /// Callback to show window and navigate to a section.
  static void Function(int? sectionIndex)? onOpenToSection;

  /// Callback to select a device by id.
  static void Function(String deviceId)? onSelectDevice;

  /// Callbacks for per-app tray actions.
  static Future<bool> Function(String package)? onClearCache;
  static Future<bool> Function(String package)? onClearData;
  static Future<bool> Function(String package)? onUninstall;

  /// Callback to refresh devices + packages.
  static Future<void> Function()? onRefresh;

  static const int sectionApps = 2;
  static const int sectionDevices = 0;

  static const int _maxTrayApps = 30;

  static List<String> _packages = [];
  static List<Device> _devices = [];
  static String? _selectedDeviceId;

  /// Updates the tray menu with current devices list.
  static Future<void> updateDevices(
    List<Device> devices,
    String? selectedDeviceId,
  ) async {
    if (!_initialized) return;
    _devices = List.from(devices);
    _selectedDeviceId = selectedDeviceId;
    await trayManager.setContextMenu(_buildMenu());
  }

  /// Updates the tray menu with current packages list.
  static Future<void> updateMenu(List<String> packages) async {
    if (!_initialized) return;
    _packages = List.from(packages);
    await trayManager.setContextMenu(_buildMenu());
  }

  /// Called early in main() — sets up close-to-hide before the UI is shown.
  static Future<void> init() async {
    if (_initialized) return;
    await windowManager.ensureInitialized();
    // Must be set before runApp so closing the window always hides instead of quitting.
    await windowManager.setPreventClose(true);
    if (!_closeListenerAdded) {
      windowManager.addListener(_WindowCloseListener());
      _closeListenerAdded = true;
    }
    _initialized = true;
  }

  /// Sets up tray icon + menu.
  static Future<void> setupTrayAndWindow() async {
    await init();

    final iconPath = Platform.isWindows
        ? 'assets/images/app_icon.ico'
        : 'assets/images/app_icon.png';
    try {
      await trayManager.setIcon(iconPath);
    } catch (_) {
      debugPrint('TrayService: setIcon failed');
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
    final items = <MenuItem>[];

    // --- Devices submenu ---
    if (_devices.isEmpty) {
      items.add(MenuItem(label: 'Devices', disabled: true));
    } else {
      final deviceItems = <MenuItem>[];
      for (final device in _devices) {
        final isSelected = device.id == _selectedDeviceId;
        final status = device.isOnline ? '' : ' (${device.state})';
        final prefix = isSelected ? '● ' : '   ';
        deviceItems.add(
          MenuItem(
            label: '$prefix${device.displayName}$status',
            disabled: !device.isOnline,
            onClick: (MenuItem item) async {
              onSelectDevice?.call(device.id);
            },
          ),
        );
      }
      items.add(
        MenuItem.submenu(
          label: 'Devices',
          submenu: Menu(items: deviceItems),
        ),
      );
    }

    // --- Apps submenu ---
    if (_packages.isEmpty) {
      items.add(MenuItem(label: 'Apps', disabled: true));
    } else {
      final appItems = <MenuItem>[];
      final showCount =
          _packages.length > _maxTrayApps ? _maxTrayApps : _packages.length;
      for (var i = 0; i < showCount; i++) {
        final package = _packages[i];
        final label = _displayName(package);
        final displayLabel =
            label.length > 40 ? '${label.substring(0, 37)}…' : label;
        appItems.add(
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
                  await onUninstall?.call(package);
                  // Refresh after uninstall so the tray list updates
                  onRefresh?.call();
                },
              ),
            ]),
          ),
        );
      }
      if (_packages.length > _maxTrayApps) {
        appItems.add(MenuItem.separator());
        appItems.add(
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
      items.add(
        MenuItem.submenu(
          label: 'Apps',
          submenu: Menu(items: appItems),
        ),
      );
    }

    // --- Refresh ---
    items.add(
      MenuItem(
        label: 'Refresh',
        onClick: (MenuItem item) async {
          onRefresh?.call();
        },
      ),
    );

    items.add(MenuItem.separator());

    // --- Open ADB Helper ---
    items.add(
      MenuItem(
        label: 'Open ADB Helper',
        onClick: (MenuItem item) async {
          onOpenToSection?.call(null);
          await windowManager.show();
          await windowManager.focus();
        },
      ),
    );

    // --- Quit ---
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
