import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leaflens/core/config/app_config.dart';
import 'package:leaflens/core/theme/app_theme.dart';
import 'package:leaflens/core/router/app_router.dart';
import 'package:leaflens/core/services/init_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await InitServices.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    const ProviderScope(
      child: LeafLensApp(),
    ),
  );
}

class LeafLensApp extends ConsumerWidget {
  const LeafLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'LeafLens',
      debugShowCheckedModeBanner: false,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}