import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/library_screen.dart';

void main() {
  runApp(const ProviderScope(child: EmberApp()));
}

class EmberApp extends StatelessWidget {
  const EmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    final inter = GoogleFonts.interTextTheme();

    return MaterialApp(
      title: 'Ember',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        useMaterial3: false,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF000000),
          onSurface: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        // Remove the ripple/highlight "touch bubble" from every button.
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all<Color?>(Colors.transparent)),
        ),
        textTheme: inter.copyWith(
          bodyLarge: inter.bodyLarge!.copyWith(color: Colors.white),
          bodySmall: inter.bodySmall!.copyWith(color: const Color(0xFF888888)),
          labelMedium: inter.labelMedium!.copyWith(color: Colors.white),
          titleMedium: inter.titleMedium!.copyWith(color: Colors.white),
        ),
      ),
      home: const LibraryScreen(),
    );
  }
}
