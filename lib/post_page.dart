import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  File? _selectedVideo;
  bool _loading = false;
  String? _selectedCommunity;

  final List<String> _communities = [
    "Flutter",
    "Teknoloji",
    "Spor",
    "Sanat",
    "Mizah",
  ];

  /// 🔹 Fotoğraf seç
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedVideo = null; // aynı anda video olmasın
      });
    }
  }

  /// 🔹 Video seç
  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImage = null; // aynı anda foto olmasın
      });
    }
  }

  /// 🔹 Görsel veya videoyu kaldır
  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  /// 🔹 Gönderi yükle
  Future<void> _uploadPost() async {
    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;
    String? mediaUrl;

    // 🔸 Görsel veya video varsa yükle
    if (_selectedImage != null || _selectedVideo != null) {
      final file = _selectedImage ?? _selectedVideo!;
      final folder = _selectedImage != null ? "images" : "videos";
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      await Supabase.instance.client.storage.from("posts").upload(fileName, file);
      mediaUrl = Supabase.instance.client.storage.from("posts").getPublicUrl(fileName);
    }

    await Supabase.instance.client.from("posts").insert({
      "user_id": user!.id,
      "title": _titleController.text.trim(),
      "content": _bodyController.text.trim(),
      "community": _selectedCommunity,
      "tags": _tagsController.text.trim(),
      "link": _linkController.text.trim(),
      "image_url": mediaUrl,
      "type": _selectedVideo != null ? "video" : "image",
    });

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
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
            // 🔹 Topluluk seçimi
            DropdownButtonFormField<String>(
              value: _selectedCommunity,
              decoration: InputDecoration(
                labelText: "Bir topluluk seç",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _communities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCommunity = v),
            ),
            const SizedBox(height: 16),

            // 🔹 Başlık
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Başlık",
                labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 🔹 Etiketler
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: "Etiket ve belirteç ekle (isteğe bağlı)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Bağlantı ekle
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: "Bağlantı ekle (isteğe bağlı)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Gövde metni
            TextField(
              controller: _bodyController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Gövde metni (isteğe bağlı)",
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Görsel veya video önizleme
            if (_selectedImage != null || _selectedVideo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, height: 200, fit: BoxFit.cover)
                        : Container(
                      height: 200,
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(Icons.videocam, size: 60, color: Colors.black54),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _removeMedia,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // 🔹 Alt ikonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bağlantı alanına link ekleyebilirsin")),
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.image_outlined), onPressed: _pickImage),
                IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: _pickVideo),
                IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: () {}),
                IconButton(icon: const Icon(Icons.campaign_outlined), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
