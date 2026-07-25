import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bus_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BusProvider(),
      child: const BusSenseApp(),
    ),
  );
}

class BusSenseApp extends StatelessWidget {
  const BusSenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    return MaterialApp(
      title: 'BusSense AI Passenger App',
      debugShowCheckedModeBanner: false,
      themeMode: busProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
