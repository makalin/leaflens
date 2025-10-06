import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaflens/features/home/presentation/pages/home_page.dart';
import 'package:leaflens/features/diagnosis/presentation/pages/camera_page.dart';
import 'package:leaflens/features/diagnosis/presentation/pages/result_page.dart';
import 'package:leaflens/features/symptoms/presentation/pages/symptoms_page.dart';
import 'package:leaflens/features/map/presentation/pages/map_page.dart';
import 'package:leaflens/features/settings/presentation/pages/settings_page.dart';
import 'package:leaflens/features/history/presentation/pages/history_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraPage(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final diagnosisResult = state.extra as Map<String, dynamic>?;
          return ResultPage(diagnosisResult: diagnosisResult);
        },
      ),
      GoRoute(
        path: '/symptoms',
        name: 'symptoms',
        builder: (context, state) => const SymptomsPage(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});