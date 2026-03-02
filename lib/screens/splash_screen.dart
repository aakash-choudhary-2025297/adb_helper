import 'package:flutter/material.dart';

import 'main_layout.dart';

/// Shows a centered linear progress indicator for 2 seconds, then [MainLayout].
/// Placeholder for a Lottie splash later.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _duration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    Future.delayed(_duration, () {
      if (!mounted) return;
      setState(() => _showMain = true);
    });
  }

  bool _showMain = false;

  @override
  Widget build(BuildContext context) {
    // Use keys so Flutter doesn't reuse element tree across transition (avoids
    // InputDecorator AnimationController assertion after hot reload).
    if (_showMain) {
      return const MainLayout(key: ValueKey('main'));
    }

    return Scaffold(
      key: const ValueKey('splash'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: LinearProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
