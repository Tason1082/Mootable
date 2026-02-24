import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    // ✅ STRING
    if (error is String) {
      return error;
    }

    // ✅ HTTP STATUS CODE
    if (error is int) {
      // AUTH
      if (error == 401) {
        return 'E-posta veya şifre yanlış.';
      }

      // YETKİ
      if (error == 403) {
        return 'Bu işlem için yetkiniz yok.';
      }

      // CLIENT HATALARI
      if (error >= 400 && error < 500) {
        return 'İstek hatalı. Lütfen bilgileri kontrol edin.';
      }

      // SERVER HATALARI
      if (error >= 500 && error < 600) {
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      }
    }

    // ✅ NETWORK
    if (error is SocketException) {
      return 'İnternet bağlantısı hatası.';
    }

    if (error is TimeoutException) {
      return 'Sunucu yanıt vermiyor.';
    }

    // ✅ GENEL EXCEPTION
    if (error is Exception) {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      if (message.toLowerCase().contains('too many requests')) {
        return 'Çok fazla istek gönderildi. Lütfen bekleyin.';
      }

      return message.isNotEmpty
          ? message
          : 'Beklenmeyen bir hata oluştu.';
    }

    return 'Beklenmeyen bir hata oluştu.';
  }

  /// 🔴 LOG
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('================ ERROR LOG ================');
    debugPrint('TYPE: ${error.runtimeType}');
    debugPrint('ERROR: $error');

    if (stackTrace != null) {
      debugPrint('STACKTRACE:\n$stackTrace');
    }

    debugPrint('==========================================');
  }

  /// 🔴 UI + LOG
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
