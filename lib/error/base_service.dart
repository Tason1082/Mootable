import 'api_exception.dart';
import 'result.dart';

class BaseService {
  static Future<Result<T>> handleRequest<T>(
      Future<T> Function() request,
      ) async {
    try {
      final result = await request();
      return Result.success(result);
    } catch (e) {
      if (e is ApiException) {
        return Result.failure(e.message);
      }

      return Result.failure("Beklenmeyen hata oluştu");
    }
  }
}