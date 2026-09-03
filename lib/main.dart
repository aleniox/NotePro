import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/system_tray_service.dart';
import 'providers/notes_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI on Windows Desktop / Linux / macOS
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final notesProvider = NotesProvider();

  // Initialize System Tray and Background Running on Windows
  if (!kIsWeb && Platform.isWindows) {
    await SystemTrayService.instance.init(
      onTogglePetCallback: () {
        notesProvider.togglePetEnabled(!notesProvider.isPetEnabled);
      },
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: notesProvider),
      ],
      child: const NoteCardsApp(),
    ),
  );
}

class NoteCardsApp extends StatelessWidget {
  const NoteCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'NoteCards Pro - Ghi Chú Thẻ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}
