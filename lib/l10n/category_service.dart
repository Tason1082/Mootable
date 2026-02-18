import 'package:dio/dio.dart';

import '../core/api_client.dart';
import 'category_model.dart';


class CategoryService {
  Future<List<CategoryModel>> getCategories(String locale) async {
    try {
      final response = await ApiClient.dio.get(
        "/api/categories",
        queryParameters: {"locale": locale},
      );

      final List data = response.data;

      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Failed to fetch categories");
    }
  }
}
