import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';


import '../core/api_config.dart';

class PostAddPage extends StatefulWidget {
  const PostAddPage({super.key});

  @override
  State<PostAddPage> createState() => _PostAddPageState();
}

class _PostAddPageState extends State<PostAddPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  final _linkController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  File? _selectedImage;
  File? _selectedVideo;

  bool _loading = false;
  String? _selectedCommunityId;

  /// Foto seç
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedVideo = null;
      });
    }
  }

  /// Video seç
  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImage = null;
      });
    }
  }

  /// Media sil
  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  Future<void> _uploadPost() async {
    setState(() => _loading = true);

    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/api/posts");
      final request = http.MultipartRequest("POST", uri);

      final token = await _storage.read(key: "token");

      if (token == null) {
        throw Exception("Token yok, login gerekli");
      }

      request.headers["Authorization"] = "Bearer $token";

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      request.fields["title"] = _titleController.text.trim();
      request.fields["content"] = _bodyController.text.trim();
      request.fields["link"] = _linkController.text.trim();
      request.fields["tags"] = jsonEncode(tags);

      if (_selectedCommunityId != null) {
        request.fields["community"] = _selectedCommunityId!;
      }

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("Media", _selectedImage!.path),
        );
      }

      if (_selectedVideo != null) {
        request.files.add(
          await http.MultipartFile.fromPath("Media", _selectedVideo!.path),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $body")),
        );
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }

    setState(() => _loading = false);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Yeni Gönderi"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              onPressed: _loading ? null : _uploadPost,
              child: Text(_loading ? "Yükleniyor..." : "Paylaş"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Başlık"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration:
              const InputDecoration(labelText: "Etiketler (virgülle)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: "Link"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: null,
              decoration: const InputDecoration(labelText: "İçerik"),
            ),
            const SizedBox(height: 16),

            /// Foto preview
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removeMedia,
                    ),
                  ),
                ],
              ),

            /// Video preview
            if (_selectedVideo != null)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, size: 64),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removeMedia,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: _pickVideo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
