import 'package:flutter/material.dart';

/// Rewards history screen with filtering and search capabilities
class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Reward History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Track all your earned rewards',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}