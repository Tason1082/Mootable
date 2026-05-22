import 'api_client.dart';
import 'package:dio/dio.dart';

class AuthApi {
  static Future<String> register({
    required String username,
    required String fullName,
    required String email,
    required String birthDate, // ISO8601 UTC tavsiye edilir
    required String gender,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        "/api/auth/register",
        data: {
          "username": username,
          "fullName": fullName,
          "email": email,
          "birthDate": birthDate,
          "gender": gender,
          "password": password,
          "confirmPassword": confirmPassword,
        },
      );

      final data = response.data;
      if (data == null) throw Exception('Sunucudan boş cevap alındı.');

      if (data['success'] != true) {
        final msg = data['message'] ?? 'Kayıt başarısız';
        final errors = data['errors'];
        throw Exception(errors != null ? '$msg: $errors' : msg);
      }

      // ApiResponse içindeki data.token veya data alanını kontrol et
      final payload = data['data'];
      String? result;
      if (payload is Map) {
        result = payload['token']?.toString() ?? payload.toString();
      } else if (payload != null) {
        result = payload.toString();
      }

      return result ?? data['message']?.toString() ?? 'Kayıt başarılı';
    } on DioError catch (e) {
      final resp = e.response?.data;
      if (resp != null && resp is Map) {
        final msg = resp['message'] ?? e.message;
        final errors = resp['errors'];
        throw Exception(errors != null ? '$msg: $errors' : msg);
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}