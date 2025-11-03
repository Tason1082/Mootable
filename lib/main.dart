import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'error_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: 'https://ywmtgfeqxvtoorxffsxj.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3bXRnZmVxeHZ0b29yeGZmc3hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NzIwNzYsImV4cCI6MjA3NDU0ODA3Nn0.2B4JFrMTzx4vsJzqMvtpYAQ1RF0jwCqLvIqtwuoPbNg',
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: true,
        autoRefreshToken: true,
      ),
    );

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _GlobalErrorHandler.handle(details.exception);
    };

    // 🔹 Uygulama ayarlarını (dil + tema) yükle
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code') ?? 'tr';
    final isDark = prefs.getBool('is_dark_mode') ?? false;

    runApp(MyApp(
      initialLocale: Locale(savedLang),
      initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    ));
  }, (error, stackTrace) {
    _GlobalErrorHandler.handle(error);
  });
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();

  // 🔹 Dil değiştirme (global erişim)
  static void setLocale(BuildContext context, Locale newLocale) async {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  // 🔹 Tema değiştirme (global erişim)
  static void setTheme(BuildContext context, bool isDark) async {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _GlobalErrorHandler.navigatorKey,
      locale: _locale,
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],

      home: const SplashPage(),
    );
  }
}

class _GlobalErrorHandler {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void handle(dynamic error) {
    final message = ErrorHandler.getErrorMessage(error);
    final context = navigatorKey.currentContext;

    if (context != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      debugPrint("⚠️ Hata (context yok): $message");
    }
  }
}
