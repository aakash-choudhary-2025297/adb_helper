import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/help_panel.dart';

const _kOutputMinHeight = 120.0;
const _kOutputMaxHeight = 600.0;
const _kOutputInitialHeight = 220.0;

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  double _outputHeight = _kOutputInitialHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Title
              Text(
                'Shell',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // 2. Collapsible header (help)
              const HelpPanel(
                title: 'Device shell (not host)',
                body:
                    'Commands run on the selected Android device—like a terminal on the phone/emulator. '
                    'Do not type "adb" here: adb runs on your computer; the device has no adb binary (that causes "adb: inaccessible or not found"). '
                    'Use device commands only, e.g. "pm list packages", "ls /sdcard", "dumpsys battery", "getprop ro.build.version.release".',
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
                const SizedBox(height: 16),
                // 3. Command run section
                const _ShellCommandRow(),
                const SizedBox(height: 20),
                // 4. Resizable output area
                _ResizableOutput(
                  height: _outputHeight,
                  minHeight: _kOutputMinHeight,
                  maxHeight: _kOutputMaxHeight.clamp(0.0, constraints.maxHeight - 100),
                  onHeightChanged: (h) => setState(() => _outputHeight = h),
                  child: const _ShellOutputContent(),
                ),
                const SizedBox(height: 24),
                // 5. Collapsible footer (history)
                const _ShellHistoryFooter(),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Draggable divider and resizable content area.
class _ResizableOutput extends StatelessWidget {
  const _ResizableOutput({
    required this.height,
    required this.minHeight,
    required this.maxHeight,
    required this.onHeightChanged,
    required this.child,
  });

  final double height;
  final double minHeight;
  final double maxHeight;
  final ValueChanged<double> onHeightChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragUpdate: (d) {
            final delta = d.delta.dy;
            final newH = (height + delta).clamp(minHeight, maxHeight);
            if (newH != height) onHeightChanged(newH);
          },
          child: Container(
            height: 12,
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: child,
        ),
      ],
    );
  }
}

class _ShellOutputContent extends StatelessWidget {
  const _ShellOutputContent();

  @override
  Widget build(BuildContext context) {
    final output = context.watch<AppState>().shellOutput;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: SelectableText(
          output.isEmpty ? 'Output will appear here…' : output,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
        ),
      ),
    );
  }
}

class _ShellCommandRow extends StatefulWidget {
  const _ShellCommandRow();

  @override
  State<_ShellCommandRow> createState() => _ShellCommandRowState();
}

class _ShellCommandRowState extends State<_ShellCommandRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    final cmd = _controller.text.trim();
    if (cmd.isEmpty) return;
    context.read<AppState>().runShell(cmd);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Device command, e.g. pm list packages or ls /sdcard',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _run(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: state.isRunningShell ? null : _run,
          icon: state.isRunningShell
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow, size: 18),
          label: const Text('Run'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => context.read<AppState>().clearShellOutput(),
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}

class _ShellHistoryFooter extends StatelessWidget {
  const _ShellHistoryFooter();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().shellHistory;
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Icon(
        Icons.history,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      ),
      title: const Text('Command history'),
      subtitle: Text(
        history.isEmpty ? 'No commands yet' : '${history.length} unique command(s)',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Run a command above to see it here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cmd = history[index];
              return ListTile(
                dense: true,
                title: Text(
                  cmd,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, size: 20),
                  tooltip: 'Run',
                  onPressed: context.watch<AppState>().isRunningShell
                      ? null
                      : () => context.read<AppState>().runShell(cmd),
                ),
                onTap: context.watch<AppState>().isRunningShell
                    ? null
                    : () => context.read<AppState>().runShell(cmd),
              );
            },
          ),
      ],
    );
  }
}
