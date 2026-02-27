import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {"Content-Type": "application/json"},
    ),
  )..httpClientAdapter = DefaultHttpClientAdapter()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },
      ),
    );

  static void allowSelfSignedCerts() {
    // Self-signed HTTPS sertifikalarını kabul et
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }
}
