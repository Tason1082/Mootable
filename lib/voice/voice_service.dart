import 'package:dio/dio.dart';

import '../core/api_client.dart';

class VoiceService {
  // Oda oluştur
  static Future<int> createRoom() async {
    final response =
    await ApiClient.dio.post("/api/voice/create-room");
    return response.data;
  }

  // Kullanıcının odalarını getir
  static Future<List<dynamic>> getMyRooms() async {
    final response =
    await ApiClient.dio.get("/api/voice/my-rooms");
    return response.data;
  }
}