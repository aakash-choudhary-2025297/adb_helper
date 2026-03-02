import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../widgets/help_panel.dart';

const _minOsInfo = 'Requires Windows 10+ or macOS 10.14+ (Mojave).';
const _adbInstallUrl = 'https://developer.android.com/studio/releases/platform-tools';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _adbPathController;

  @override
  void initState() {
    super.initState();
    _adbPathController = TextEditingController(text: context.read<AppState>().adbPath);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = context.read<AppState>().adbPath;
    if (_adbPathController.text != current) {
      _adbPathController.text = current;
    }
  }

  @override
  void dispose() {
    _adbPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const HelpPanel(
            initiallyExpanded: true,
            title: 'ADB not installed?',
            body:
                'Install Android Platform Tools and add "platform-tools" to your PATH, or set the full path to adb below. '
                'Download: $_adbInstallUrl',
          ),
          const SizedBox(height: 24),
          Text('ADB path', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _adbPathController,
                  decoration: const InputDecoration(
                    hintText: 'adb',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: context.watch<AppState>().isValidatingAdb
                    ? null
                    : () => _validateAndSave(context),
                child: Text(context.watch<AppState>().isValidatingAdb ? 'Checking…' : 'Validate & save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final adbValid = context.watch<AppState>().adbValid;
              if (adbValid == true) {
                return Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('ADB found and working.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                );
              }
              if (adbValid == false) {
                return Row(
                  children: [
                    Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ADB not found or failed. Check path or install platform-tools.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 32),
          Text('About', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_minOsInfo, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  const LinkButton(url: _adbInstallUrl, label: 'Download Android Platform Tools'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndSave(BuildContext context) async {
    final path = _adbPathController.text.trim();
    if (path.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an ADB path (e.g. adb or full path).')),
        );
      }
      return;
    }
    final appState = context.read<AppState>();
    await appState.setAdbPath(path);
    final ok = await appState.validateAdb();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'ADB path saved and valid.' : 'ADB path invalid or not found.')),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(label),
    );
  }
}
