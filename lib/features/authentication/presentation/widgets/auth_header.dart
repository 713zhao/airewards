import 'package:flutter/material.dart';

/// Header widget for authentication screens with title and subtitle
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leadingWidget;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingWidget != null) ...[
          leadingWidget!,
          const SizedBox(height: 24),
        ],
        
        // Title
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}