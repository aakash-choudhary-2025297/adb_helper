import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/help_panel.dart';

/// Derives a short display name from a package (e.g. com.i2e1.wiom_gold → Wiom).
String _displayNameFromPackage(String package) {
  final last = package.split('.').last;
  if (last.isEmpty) return package;
  final first = last.split('_').first;
  if (first.isEmpty) return last;
  return first.length == 1
      ? first.toUpperCase()
      : '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
}

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final _filterController = TextEditingController();
  String? _lastLoadedDeviceId;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      final deviceId = state.selectedDeviceId;
      if (deviceId != null &&
          deviceId != _lastLoadedDeviceId &&
          !state.isLoadingPackages) {
        _lastLoadedDeviceId = deviceId;
        state.loadPackages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Apps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const HelpPanel(
            title: 'Packages and actions',
            body:
                'Lists installed apps (package names). By default only third-party apps are shown; '
                'turn on "Show system packages" to include system apps. "Clear cache" removes temporary files; '
                '"Clear data" removes all app data (logins, settings). "Uninstall" removes the app entirely and cannot be undone.',
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              if (context.watch<AppState>().selectedDeviceId == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select a device on the Devices tab first.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (context.watch<AppState>().selectedDeviceId != null) ...[
            Row(
              children: [
                _RefreshButton(),
                const SizedBox(width: 16),
                Expanded(
                  child: _ShowSystemSwitch(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _filterController,
              decoration: const InputDecoration(
                hintText: 'Filter by package name…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _PackagesList(filter: _filterController.text.trim().toLowerCase()),
          ],
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return FilledButton.icon(
      onPressed: state.isLoadingPackages
          ? null
          : () => context.read<AppState>().loadPackages(),
      icon: state.isLoadingPackages
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 18),
      label: Text(state.isLoadingPackages ? 'Loading…' : 'Refresh'),
    );
  }
}

class _ShowSystemSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Switch(
          value: state.includeSystemPackages,
          onChanged: state.isLoadingPackages
              ? null
              : (value) => state.loadPackages(includeSystem: value),
        ),
        title: const Text('Show system packages'),
      ),
    );
  }
}

class _PackagesList extends StatelessWidget {
  const _PackagesList({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.packagesError != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(state.packagesError!),
        ),
      );
    }
    final packages = filter.isEmpty
        ? state.packages
        : state.packages.where((p) => p.toLowerCase().contains(filter)).toList();
    if (state.packages.isEmpty && !state.isLoadingPackages) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              state.includeSystemPackages
                  ? 'No packages on this device.'
                  : 'No third-party apps found. Enable "Show system packages" to see system apps.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (packages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No packages match the filter.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final package = packages[index];
          final showFriendlyName = !context.watch<AppState>().includeSystemPackages;
          final title = showFriendlyName ? _displayNameFromPackage(package) : package;
          final subtitle = showFriendlyName ? package : null;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.apps,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: showFriendlyName ? null : 'monospace',
                fontSize: showFriendlyName ? 15 : 13,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _onAction(context, value, package),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'clear_cache', child: Text('Clear cache')),
                const PopupMenuItem(value: 'clear_data', child: Text('Clear data')),
                const PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action, String package) async {
    final state = context.read<AppState>();
    switch (action) {
      case 'clear_cache':
        final ok = await showConfirmDialog(
          context,
          title: 'Clear cache',
          message: 'Clear cache for "$package"?',
          confirmLabel: 'Clear cache',
        );
        if (ok && context.mounted) {
          final success = await state.clearPackageCache(package);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Cache cleared.' : 'Failed to clear cache.')),
            );
          }
        }
        break;
      case 'clear_data':
        final ok = await showConfirmDialog(
          context,
          title: 'Clear data',
          message: 'Clear all data for "$package"? Logins and local data will be removed.',
          confirmLabel: 'Clear data',
          isDestructive: true,
        );
        if (ok && context.mounted) {
          final success = await state.clearPackageData(package);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Data cleared.' : 'Failed to clear data.')),
            );
          }
        }
        break;
      case 'uninstall':
        final ok = await showConfirmDialog(
          context,
          title: 'Uninstall',
          message: 'Uninstall "$package"? This cannot be undone.',
          confirmLabel: 'Uninstall',
          isDestructive: true,
        );
        if (ok && context.mounted) {
          final success = await state.uninstallPackage(package);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Uninstalled.' : 'Uninstall failed.')),
            );
          }
        }
        break;
    }
  }
}
