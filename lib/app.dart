import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

/// Ana uygulama widget'ı
class MirrorCamApp extends StatelessWidget {
  /// Sabit yapıcı
  const MirrorCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MirrorCam',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Kurallar gereği varsayılan dark theme
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
