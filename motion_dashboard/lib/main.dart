import 'package:flutter/material.dart';
import 'package:motion_dashboard/providers/theme_provider.dart';
import 'package:motion_dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motion Dashboard',
      theme: themeProvider.currentTheme,
      home: const DashboardScreen(),
    );
  }
}
