import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// BusSense AI Unified Mobile Root Application Widget
class BusSenseApp extends StatelessWidget {
  const BusSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusSense AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRouter(),
    );
  }
}
