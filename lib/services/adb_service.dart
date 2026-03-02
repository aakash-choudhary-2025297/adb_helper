import 'dart:convert';
import 'dart:io';

import '../models/device.dart';

/// Runs ADB commands via the host's adb binary (PATH or custom path).
class AdbService {
  /// Runs [args] with adb. [adbPath] is the executable (e.g. 'adb' or '/path/to/adb').
  static Future<ProcessResult> run(
    String adbPath,
    List<String> args, {
    bool includeStderr = true,
  }) async {
    return Process.run(
      adbPath,
      args,
      runInShell: false,
      stderrEncoding: includeStderr ? utf8 : null,
      stdoutEncoding: utf8,
    );
  }

  /// Returns true if [adbPath] is valid (e.g. running `adb version` succeeds).
  static Future<bool> validatePath(String adbPath) async {
    if (adbPath.trim().isEmpty) return false;
    final result = await run(adbPath.trim(), ['version']);
    return result.exitCode == 0;
  }

  /// Fetches connected devices. Uses `adb devices -l` for model info.
  /// Throws [AdbException] if adb fails (e.g. permission denied, not found).
  static Future<List<Device>> getDevices(String adbPath) async {
    final result = await run(adbPath, ['devices', '-l']);
    if (result.exitCode != 0) {
      final err = (result.stderr as String?)?.trim() ?? '';
      final out = (result.stdout as String?)?.trim() ?? '';
      throw AdbException(
        result.exitCode,
        err.isNotEmpty ? err : out,
      );
    }
    return _parseDevices(result.stdout as String);
  }

  static List<Device> _parseDevices(String output) {
    const header = 'List of devices attached';
    final lines = output.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final list = <Device>[];
    for (final line in lines) {
      if (line == header) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final id = parts[0];
      final state = parts[1];
      String? model;
      for (var i = 2; i < parts.length; i++) {
        if (parts[i].startsWith('model:')) {
          model = parts[i].substring(6);
          break;
        }
      }
      list.add(Device(id: id, state: state, model: model));
    }
    return list;
  }

  /// Runs a shell command on [deviceId]. Returns combined stdout and stderr.
  static Future<ShellResult> shell(String adbPath, String deviceId, String command) async {
    final result = await run(adbPath, ['-s', deviceId, 'shell', command]);
    final out = (result.stdout as String?) ?? '';
    final err = (result.stderr as String?) ?? '';
    return ShellResult(
      exitCode: result.exitCode,
      stdout: out,
      stderr: err,
    );
  }

  /// Lists installed package names on [deviceId].
  /// [thirdPartyOnly] when true uses `pm list packages -3` (user-installed only; hides system).
  static Future<List<String>> getPackages(
    String adbPath,
    String deviceId, {
    bool thirdPartyOnly = true,
  }) async {
    final cmd = thirdPartyOnly ? 'pm list packages -3' : 'pm list packages';
    final result = await shell(adbPath, deviceId, cmd);
    if (result.exitCode != 0) return [];
    final lines = (result.stdout + result.stderr).split('\n');
    const prefix = 'package:';
    return lines
        .map((s) => s.trim())
        .where((s) => s.startsWith(prefix))
        .map((s) => s.substring(prefix.length))
        .toList();
  }

  /// Uninstalls [packageName] from [deviceId].
  static Future<ProcessResult> uninstall(String adbPath, String deviceId, String packageName) async {
    return run(adbPath, ['-s', deviceId, 'uninstall', packageName]);
  }

  /// Clears app cache for [packageName] on [deviceId].
  static Future<ShellResult> clearCache(String adbPath, String deviceId, String packageName) async {
    return shell(adbPath, deviceId, 'pm clear --cache-only $packageName');
  }

  /// Clears all app data for [packageName] on [deviceId].
  static Future<ShellResult> clearData(String adbPath, String deviceId, String packageName) async {
    return shell(adbPath, deviceId, 'pm clear $packageName');
  }
}

class ShellResult {
  const ShellResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Thrown when an ADB command fails (non-zero exit or process error).
class AdbException implements Exception {
  AdbException(this.exitCode, this.message);

  final int exitCode;
  final String message;

  @override
  String toString() => message.isNotEmpty ? '$message (exit code: $exitCode)' : 'ADB failed (exit code: $exitCode)';
}
