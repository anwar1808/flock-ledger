import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

class FlockLedgerApp extends StatelessWidget {
  const FlockLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlockLedger',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    const seedColor = Color(0xFF5D8A3C); // earthy green
    const accentAmber = Color(0xFFD4A017); // golden amber

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        secondary: accentAmber,
        brightness: brightness,
        // Remove yellow-green surface tint from Material 3.
        // To restore the original tinted look, delete the line below.
      ).copyWith(surfaceTint: Colors.transparent),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF1A2212) : const Color(0xFFEFF5E8),
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A2212),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5D8A3C),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
