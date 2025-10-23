import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    // 🔹 1. Supabase Auth Exception
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Geçersiz e-posta veya şifre.';
      } else if (msg.contains('email not confirmed')) {
        return 'E-posta adresiniz doğrulanmamış.';
      } else if (msg.contains('user not found')) {
        return 'Kullanıcı bulunamadı.';
      } else if (msg.contains('password')) {
        return 'Şifre hatalı veya geçersiz.';
      }
      return 'Kimlik doğrulama hatası: ${error.message}';
    }

    // 🔹 2. Supabase PostgrestException (veritabanı sorguları)
    if (error is PostgrestException) {
      return 'Veritabanı hatası: ${error.message}';
    }

    // 🔹 3. Ağ (internet) hataları
    if (error is SocketException) {
      return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
    }

    // 🔹 4. Timeout veya sunucu yanıt vermedi
    if (error is TimeoutException) {
      return 'Sunucu yanıt vermiyor. Lütfen tekrar deneyin.';
    }

    // 🔹 5. Genel hata mesajları
    final message = error.toString().toLowerCase();
    if (message.contains('too many requests')) {
      return 'Çok fazla istek gönderildi. Lütfen bekleyin.';
    } else if (message.contains('network')) {
      return 'Ağ bağlantısı hatası.';
    }

    // 🔹 6. Bilinmeyen hata
    return 'Bir hata oluştu: ${error.toString()}';
  }

  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

