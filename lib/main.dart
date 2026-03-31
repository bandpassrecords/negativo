import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:negativo/l10n/app_localizations.dart' show AppLocalizations;
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'services/film_service.dart';
import 'services/scoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en', null);
  await initializeDateFormatting('pt', null);

  await HiveService.init();
  await NotificationService.init();
  await ScoringService.init();

  // Check if any developing rolls have completed
  await FilmService.checkDevelopmentCompletions();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static VoidCallback? updateLanguageCallback;
  static VoidCallback? updateThemeCallback;

  static void updateLanguage() => updateLanguageCallback?.call();
  static void updateTheme() => updateThemeCallback?.call();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    MyApp.updateLanguageCallback = _loadSettings;
    MyApp.updateThemeCallback = _loadSettings;
  }

  @override
  void dispose() {
    MyApp.updateLanguageCallback = null;
    MyApp.updateThemeCallback = null;
    super.dispose();
  }

  void _loadSettings() {
    final settings = HiveService.getSettings();
    setState(() {
      _locale = Locale(settings.language);
      switch (settings.themeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
        case 'dark':
          _themeMode = ThemeMode.dark;
        default:
          _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFB8860B); // dark goldenrod — analog amber

    return MaterialApp(
      title: 'Negativo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
      ],
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: const MainScreen(),
    );
  }
}
