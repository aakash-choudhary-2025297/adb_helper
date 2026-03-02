import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/help_panel.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Devices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const HelpPanel(
            title: 'What are devices?',
            body:
                'Devices are Android phones or emulators connected to this computer via USB or wireless debugging. '
                'Enable "USB debugging" in Developer options on your phone and connect it. '
                'Select one device below to use it for Shell and Apps. You can only use one device at a time.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton.icon(
                onPressed: context.watch<AppState>().isLoadingDevices
                    ? null
                    : () => context.read<AppState>().loadDevices(),
                icon: context.watch<AppState>().isLoadingDevices
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(context.watch<AppState>().isLoadingDevices ? 'Refreshing…' : 'Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final state = context.watch<AppState>();
              if (state.devicesError != null) {
                return Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(state.devicesError!),
                  ),
                );
              }
              if (state.devices.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No devices found. Connect a device with USB debugging enabled, or start an emulator.',
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
                  itemCount: state.devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = state.devices[index];
                    final selected = state.selectedDeviceId == device.id;
                    return ListTile(
                      leading: Icon(
                        device.isOnline ? Icons.phone_android : Icons.phone_android_outlined,
                        color: device.isOnline ? null : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(device.displayName),
                      subtitle: Text('${device.id} · ${device.state}'),
                      selected: selected,
                      onTap: device.isOnline
                          ? () => context.read<AppState>().selectDevice(device.id)
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
