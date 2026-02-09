import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = (error.message ?? '').toLowerCase();

      if (msg.contains('invalid login credentials')) {
        return 'Geçersiz e-posta veya şifre.';
      } else if (msg.contains('email not confirmed')) {
        return 'E-posta adresiniz doğrulanmamış.';
      } else if (msg.contains('user not found')) {
        return 'Kullanıcı bulunamadı.';
      } else if (msg.contains('password')) {
        return 'Şifre hatalı veya geçersiz.';
      }

      return 'Kimlik doğrulama hatası.';
    }

    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'Bu işlem için yetkiniz yok.';
      }
      return 'Veritabanı işlemi sırasında hata oluştu.';
    }

    if (error is SocketException) {
      return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
    }

    if (error is TimeoutException) {
      return 'Sunucu yanıt vermiyor. Lütfen tekrar deneyin.';
    }

    final message = error is Exception
        ? error.toString().toLowerCase()
        : '';

    if (message.contains('too many requests')) {
      return 'Çok fazla istek gönderildi. Lütfen bekleyin.';
    }

    return 'Beklenmeyen bir hata oluştu.';
  }


  /// 🔴 HER ŞEY BURAYA LOG DÜŞER
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('================ ERROR LOG ================');
    debugPrint('TYPE: ${error.runtimeType}');
    debugPrint('ERROR: $error');

    if (error is AuthException) {
      debugPrint('AUTH MESSAGE: ${error.message}');
      debugPrint('STATUS CODE: ${error.statusCode}');
    }

    if (error is PostgrestException) {
      debugPrint('POSTGREST MESSAGE: ${error.message}');
      debugPrint('DETAILS: ${error.details}');
      debugPrint('HINT: ${error.hint}');
      debugPrint('CODE: ${error.code}');
    }

    if (stackTrace != null) {
      debugPrint('STACKTRACE:\n$stackTrace');
    }

    debugPrint('==========================================');

    // 🔥 Production için hazır
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// 🔴 UI + LOG AYNI ANDA
  static void showError(
      BuildContext context,
      dynamic error, {
        StackTrace? stackTrace,
      }) {
    logError(error, stackTrace);

    final message = getErrorMessage(error);
    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });


  }
}

