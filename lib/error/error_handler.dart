import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'api_error.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {

    /// ✅ BACKEND ERROR (EN ÖNEMLİ)
    if (error is ApiError) {
      // Validation
      if (error.errors != null && error.errors!.isNotEmpty) {
        return error.errors!.values.first.first;
      }

      // Direkt backend mesajı
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    /// ✅ DIO RESPONSE (varsa)
    if (error is DioException && error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        final apiError = ApiError.fromJson(data);
        return getErrorMessage(apiError);
      }
    }

    /// ✅ HTTP STATUS (fallback)
    if (error is int) {
      if (error == 401) return 'E-posta veya şifre yanlış.';
      if (error == 403) return 'Bu işlem için yetkiniz yok.';
      if (error >= 400 && error < 500) {
        return 'İstek hatalı.';
      }
      if (error >= 500) {
        return 'Sunucu hatası.';
      }
    }

    /// ✅ NETWORK
    if (error is SocketException) {
      return 'İnternet bağlantısı hatası.';
    }

    if (error is TimeoutException) {
      return 'Sunucu yanıt vermiyor.';
    }

    /// ✅ DEFAULT
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
