import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'error_handler.dart';

// ✅ Yeni doğru import
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ywmtgfeqxvtoorxffsxj.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3bXRnZmVxeHZ0b29yeGZmc3hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NzIwNzYsImV4cCI6MjA3NDU0ODA3Nn0.2B4JFrMTzx4vsJzqMvtpYAQ1RF0jwCqLvIqtwuoPbNg',
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _GlobalErrorHandler.handle(details.exception);
  };

  runZonedGuarded(
        () => runApp(const MyApp()),
        (error, stackTrace) {
      _GlobalErrorHandler.handle(error);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _GlobalErrorHandler.navigatorKey,

      // 🌍 Dil desteği ayarları:
      localizationsDelegates: const [
        AppLocalizations.delegate, // .arb dosyalarından üretilen sınıf
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🔤 Desteklenen diller (ARB dosyalarına göre)
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],

      // 🏠 Başlangıç sayfan
      home: const SplashPage(),
    );
  }
}

/// 🔥 Global hata yakalayıcı
class _GlobalErrorHandler {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void handle(dynamic error) {
    final message = ErrorHandler.getErrorMessage(error);

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      debugPrint("Hata (context yok): $message");
    }
  }
}
