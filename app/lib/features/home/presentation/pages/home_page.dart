import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leaflens/features/home/presentation/widgets/quick_action_card.dart';
import 'package:leaflens/features/home/presentation/widgets/recent_diagnosis_card.dart';
import 'package:leaflens/features/home/presentation/widgets/stats_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeafLens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to LeafLens',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diagnose plant health issues with AI-powered analysis',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                QuickActionCard(
                  title: 'Diagnose Plant',
                  subtitle: 'Take a photo to analyze',
                  icon: Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => context.push('/camera'),
                ),
                QuickActionCard(
                  title: 'Symptom Checker',
                  subtitle: 'Describe symptoms',
                  icon: Icons.quiz,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => context.push('/symptoms'),
                ),
                QuickActionCard(
                  title: 'Outbreak Map',
                  subtitle: 'View regional issues',
                  icon: Icons.map,
                  color: Colors.orange,
                  onTap: () => context.push('/map'),
                ),
                QuickActionCard(
                  title: 'Care Guide',
                  subtitle: 'Learn plant care',
                  icon: Icons.menu_book,
                  color: Colors.green,
                  onTap: () {
                    // TODO: Implement care guide
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Care guide coming soon!')),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Stats Section
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            const StatsCard(),
            
            const SizedBox(height: 24),
            
            // Recent Diagnoses
            Text(
              'Recent Diagnoses',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            const RecentDiagnosisCard(),
          ],
        ),
      ),
    );
  }
}