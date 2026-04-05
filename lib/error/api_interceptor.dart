import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = "Bilinmeyen hata oluştu";

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        message = "Bağlantı zaman aşımına uğradı";
        break;

      case DioExceptionType.sendTimeout:
        message = "İstek gönderilemedi";
        break;

      case DioExceptionType.receiveTimeout:
        message = "Sunucu yanıt vermedi";
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;

        if (statusCode == 401) {
          message = "Oturum süresi doldu";
        } else if (statusCode == 404) {
          message = "Kaynak bulunamadı";
        } else if (statusCode == 500) {
          message = "Sunucu hatası";
        } else {
          message = err.response?.data?["message"] ?? "Bir hata oluştu";
        }
        break;

      case DioExceptionType.cancel:
        message = "İstek iptal edildi";
        break;

      case DioExceptionType.unknown:
        message = "İnternet bağlantısı yok";
        break;

      default:
        message = "Bir hata oluştu";
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(
          message: message,
          statusCode: err.response?.statusCode,
        ),
      ),
    );
  }
}