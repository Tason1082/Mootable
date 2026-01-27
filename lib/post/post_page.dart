import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  File? _selectedImage;
  bool _loading = false;

  String? _selectedCommunityId;

  /// Foto seç
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// Media sil
  void _removeMedia() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// API'ye gönder
  Future<void> _uploadPost() async {
    setState(() => _loading = true);

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/posts");

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      final body = {
        "title": _titleController.text.trim(),
        "content": _bodyController.text.trim(),
        "imageUrl": null, // şimdilik null
        "link": _linkController.text.trim(),
        "community": _selectedCommunityId,
        "tags": tags,
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("✅ Post eklendi");

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        debugPrint("❌ API Error");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("🔥 Exception: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bağlantı hatası")),
      );
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
              decoration: const InputDecoration(
                labelText: "Başlık",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: "Etiketler (virgülle)",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: "Link",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _bodyController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "İçerik",
              ),
            ),

            const SizedBox(height: 16),

            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
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

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

