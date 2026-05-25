import 'api_response.dart';

class ApiHelper {
  static ApiResponse<T> parse<T>(
      dynamic response,
      T Function(dynamic json)? fromJsonT,
      ) {
    final apiResponse = ApiResponse<T>.fromJson(
      response.data,
      fromJsonT,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? "Bir hata oluştu",
      );
    }

    return apiResponse;
  }
}