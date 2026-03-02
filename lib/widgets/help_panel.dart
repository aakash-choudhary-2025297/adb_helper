import 'package:flutter/material.dart';

/// Collapsible in-app help panel with title and body text.
class HelpPanel extends StatelessWidget {
  const HelpPanel({
    super.key,
    required this.title,
    required this.body,
    this.initiallyExpanded = false,
  });

  final String title;
  final String body;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
          child: Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
