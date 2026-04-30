import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';

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

  String? _selectedCommunityName;

  // ✅ MULTIPLE MEDIA
  List<File> _selectedMedia = [];

  bool _loading = false;

  // COMMUNITY
  List<Map<String, dynamic>> _communities = [];
  bool _loadingCommunities = true;

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  // ================= COMMUNITY =================
  Future<void> _fetchCommunities() async {
    try {
      final response = await ApiClient.dio.get("/api/communities");

      final data = response.data;
      List listData = data is List ? data : data["data"];

      setState(() {
        _communities = listData.map((e) => {
          "id": e["id"].toString(),
          "name": e["name"],
        }).toList();
        _loadingCommunities = false;
      });
    } catch (e) {
      debugPrint("Topluluk çekme hatası: $e");
      setState(() => _loadingCommunities = false);
    }
  }

  // ================= MEDIA =================

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedMedia.add(File(picked.path));
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  // ================= UPLOAD =================

  Future<void> _uploadPost() async {
    setState(() => _loading = true);

    try {
      ApiClient.allowSelfSignedCerts();

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final userId = await AuthService.getUserId();
      if (userId == null) throw Exception("Kullanıcı ID alınamadı");

      FormData formData = FormData.fromMap({
        "title": _titleController.text.trim(),
        "content": _bodyController.text.trim(),
        "link": _linkController.text.trim(),
        "tags": tags,
        "user": userId,

        if (_selectedCommunityName != null)
          "community": _selectedCommunityName,
      });

      // ✅ MULTIPLE FILE SEND
      for (var file in _selectedMedia) {
        formData.files.add(
          MapEntry(
            "MediaFiles",
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await ApiClient.dio.post(
        "/api/posts",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${response.data}")),
        );
      }
    } catch (e) {
      debugPrint("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }

    setState(() => _loading = false);
  }

  // ================= UI =================

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
          children: [
            // COMMUNITY
            _loadingCommunities
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
              value: _selectedCommunityName,
              hint: const Text("Topluluk seç"),
              items: _communities.map((c) {
                return DropdownMenuItem<String>(
                  value: c["name"],
                  child: Text(c["name"]),
                );
              }).toList(),
              onChanged: (v) => setState(() {
                _selectedCommunityName = v;
              }),
            ),

            const SizedBox(height: 12),

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

            // ✅ MEDIA PREVIEW
            if (_selectedMedia.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final file = _selectedMedia[index];
                    final isVideo = file.path.endsWith(".mp4") ||
                        file.path.endsWith(".mov");

                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isVideo
                                ? Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Icon(Icons.play_circle_fill,
                                    size: 50),
                              ),
                            )
                                : Image.file(file, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeMedia(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImages, // ✅ FIXED
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
