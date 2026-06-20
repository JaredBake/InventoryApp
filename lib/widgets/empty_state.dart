import 'package:flutter/material.dart';

/// Placeholder shown when a list is empty.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
