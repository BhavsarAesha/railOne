import 'package:flutter/material.dart';

// Decorative gradient header used in multiple screens.
class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const GradientHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const FlutterLogo(size: 48),
        ],
      ),
    );
  }
}

