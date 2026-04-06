import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const EmojiRiddleApp(),
    ),
  );
}

class EmojiRiddleApp extends StatelessWidget {
  const EmojiRiddleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        
        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.light,
            seedColor: const Color(0xFF5543CF),
            background: const Color(0xFFFBF4FF),
            surface: const Color(0xFFFBF4FF),
            primary: const Color(0xFF5543CF),
            secondary: const Color(0xFF5AF9F3),
            error: const Color(0xFFB41340),
          ),
          textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.light().textTheme),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color(0xFF5543CF),
            background: const Color(0xFF1E1E2C),
            surface: const Color(0xFF1E1E2C),
            primary: const Color(0xFF9E93FF), // Lighter primary for dark mode
            surfaceContainerLow: const Color(0xFF2A2A3C),
            surfaceContainerHigh: const Color(0xFF383850),
            surfaceContainerHighest: const Color(0xFF454563),
          ),
          textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.dark().textTheme),
        );

        return MaterialApp(
          title: 'Emoji Bilmece',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode ? darkTheme : lightTheme,
          home: _getHomeRoute(authProvider),
        );
      },
    );
  }

  Widget _getHomeRoute(AuthProvider auth) {
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.isAuthenticated) {
      return const MainScreen();
    }
    return const LoginScreen();
  }
}
