import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'error_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  // 🔹 runZonedGuarded ile zone uyumu sağlanıyor
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🔹 Supabase initialize
    await Supabase.initialize(
      url: 'https://ywmtgfeqxvtoorxffsxj.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3bXRnZmVxeHZ0b29yeGZmc3hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NzIwNzYsImV4cCI6MjA3NDU0ODA3Nn0.2B4JFrMTzx4vsJzqMvtpYAQ1RF0jwCqLvIqtwuoPbNg',
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: true,
        autoRefreshToken: true,
      ),
    );

    // 🔹 Flutter hatalarını global yakalama
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _GlobalErrorHandler.handle(details.exception);
    };

    // 🔹 Uygulamayı başlat
    runApp(const MyApp());
  }, (error, stackTrace) {
    _GlobalErrorHandler.handle(error);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _GlobalErrorHandler.navigatorKey,

      // 🌍 Dil desteği
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

      // 🏠 Başlangıç sayfası
      home: const SplashPage(),
    );
  }
}

/// 🔥 Global hata yöneticisi
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
