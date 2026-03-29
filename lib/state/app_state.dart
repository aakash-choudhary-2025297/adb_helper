import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../services/adb_service.dart';
import '../services/settings_service.dart';
import '../services/tray_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._settings);

  final SettingsService _settings;

  String get adbPath => _settings.adbPath;

  List<Device> _devices = [];
  List<Device> get devices => List.unmodifiable(_devices);

  String? _selectedDeviceId;
  String? get selectedDeviceId => _selectedDeviceId;
  Device? get selectedDevice =>
      _devices.cast<Device?>().firstWhere((d) => d?.id == _selectedDeviceId, orElse: () => null);

  bool _isLoadingDevices = false;
  bool get isLoadingDevices => _isLoadingDevices;
  String? _devicesError;
  String? get devicesError => _devicesError;

  bool _isValidatingAdb = false;
  bool get isValidatingAdb => _isValidatingAdb;
  bool? _adbValid;
  bool? get adbValid => _adbValid;

  Future<void> setAdbPath(String path) async {
    await _settings.setAdbPath(path);
    _adbValid = null;
    notifyListeners();
  }

  Future<bool> validateAdb() async {
    _isValidatingAdb = true;
    _adbValid = null;
    notifyListeners();
    try {
      _adbValid = await AdbService.validatePath(_settings.adbPath);
      return _adbValid!;
    } finally {
      _isValidatingAdb = false;
      notifyListeners();
    }
  }

  Future<void> loadDevices() async {
    _isLoadingDevices = true;
    _devicesError = null;
    notifyListeners();
    try {
      _devices = await AdbService.getDevices(_settings.adbPath);
      _devicesError = null;
      final online = _devices.where((d) => d.isOnline).toList();
      if (_selectedDeviceId != null && !online.any((d) => d.id == _selectedDeviceId)) {
        _selectedDeviceId = online.isNotEmpty ? online.first.id : null;
      }
      if (_selectedDeviceId == null && online.isNotEmpty) {
        _selectedDeviceId = online.first.id;
      }
    } catch (e, st) {
      _devices = [];
      _devicesError = e.toString();
      debugPrintStack(stackTrace: st, label: e.toString());
    } finally {
      _isLoadingDevices = false;
      notifyListeners();
      if (Platform.isMacOS || Platform.isWindows) {
        TrayService.updateDevices(_devices, _selectedDeviceId);
      }
    }
  }

  void selectDevice(String? deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
    if (Platform.isMacOS || Platform.isWindows) {
      TrayService.updateDevices(_devices, _selectedDeviceId);
    }
  }

  /// Refreshes both devices and packages, then updates the tray menu.
  Future<void> refreshAll() async {
    await loadDevices();
    if (_selectedDeviceId != null) {
      await loadPackages();
    }
  }

  // --- Shell ---
  String _shellOutput = '';
  String get shellOutput => _shellOutput;
  bool _isRunningShell = false;
  bool get isRunningShell => _isRunningShell;

  List<String> _shellHistory = [];
  List<String> get shellHistory => List.unmodifiable(_shellHistory);

  Future<void> runShell(String command) async {
    if (_selectedDeviceId == null) return;
    final cmd = command.trim();
    if (cmd.isNotEmpty) {
      _shellHistory = [cmd, ..._shellHistory.where((c) => c != cmd)];
      if (_shellHistory.length > 50) _shellHistory = _shellHistory.take(50).toList();
    }
    _isRunningShell = true;
    _shellOutput = '';
    notifyListeners();
    try {
      final result = await AdbService.shell(
        _settings.adbPath,
        _selectedDeviceId!,
        command,
      );
      final out = result.stdout.trim();
      final err = result.stderr.trim();
      _shellOutput = [
        if (out.isNotEmpty) out,
        if (err.isNotEmpty) '[stderr]\n$err',
        'Exit code: ${result.exitCode}',
      ].join('\n\n');
    } catch (e) {
      _shellOutput = 'Error: $e';
    } finally {
      _isRunningShell = false;
      notifyListeners();
    }
  }

  void clearShellOutput() {
    _shellOutput = '';
    notifyListeners();
  }

  // --- Packages ---
  List<String> _packages = [];
  List<String> get packages => List.unmodifiable(_packages);
  bool _isLoadingPackages = false;
  bool get isLoadingPackages => _isLoadingPackages;
  String? _packagesError;
  String? get packagesError => _packagesError;
  bool _includeSystemPackages = false;
  bool get includeSystemPackages => _includeSystemPackages;

  /// Loads packages for the selected device. By default only third-party (user) apps are loaded.
  /// Set [includeSystem] to true to include system packages.
  Future<void> loadPackages({bool? includeSystem}) async {
    if (_selectedDeviceId == null) return;
    if (includeSystem != null) _includeSystemPackages = includeSystem;
    _isLoadingPackages = true;
    _packagesError = null;
    notifyListeners();
    try {
      _packages = await AdbService.getPackages(
        _settings.adbPath,
        _selectedDeviceId!,
        thirdPartyOnly: !_includeSystemPackages,
      );
    } catch (e) {
      _packages = [];
      _packagesError = e.toString();
    } finally {
      _isLoadingPackages = false;
      notifyListeners();
      if (Platform.isMacOS || Platform.isWindows) {
        TrayService.updateMenu(_packages);
      }
    }
  }

  Future<bool> uninstallPackage(String packageName) async {
    if (_selectedDeviceId == null) return false;
    try {
      final result = await AdbService.uninstall(
        _settings.adbPath,
        _selectedDeviceId!,
        packageName,
      );
      if (result.exitCode == 0) {
        _packages = _packages.where((p) => p != packageName).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearPackageCache(String packageName) async {
    if (_selectedDeviceId == null) return false;
    try {
      final result = await AdbService.clearCache(
        _settings.adbPath,
        _selectedDeviceId!,
        packageName,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearPackageData(String packageName) async {
    if (_selectedDeviceId == null) return false;
    try {
      final result = await AdbService.clearData(
        _settings.adbPath,
        _selectedDeviceId!,
        packageName,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
