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

  String? _selectedCommunityId;

  // 🔹 Communities (id + name almak ZORUNLU)
  List<Map<String, dynamic>> _communities = [];
  bool _isLoadingCommunities = true;

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  /// 🔹 Supabase'den communities çek
  Future<void> _fetchCommunities() async {
    final response = await Supabase.instance.client
        .from('communities')
        .select('id, name')
        .order('name');

    setState(() {
      _communities = List<Map<String, dynamic>>.from(response);
      _isLoadingCommunities = false;
    });
  }

  /// 🔹 Fotoğraf seç
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedVideo = null;
      });
    }
  }

  /// 🔹 Video seç
  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
        _selectedImage = null;
      });
    }
  }

  /// 🔹 Medya kaldır
  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  /// 🔹 Post yükle
  Future<void> _uploadPost() async {
    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;
    String? mediaUrl;

    if (_selectedImage != null || _selectedVideo != null) {
      final file = _selectedImage ?? _selectedVideo!;
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";

      await Supabase.instance.client.storage
          .from("posts")
          .upload(fileName, file);

      mediaUrl = Supabase.instance.client.storage
          .from("posts")
          .getPublicUrl(fileName);
    }

    await Supabase.instance.client.from("posts").insert({
      "user_id": user!.id,
      "title": _titleController.text.trim(),
      "content": _bodyController.text.trim(),
      "community": _selectedCommunityId, // 👈 SADECE BURASI DEĞİŞTİ
      "tags": _tagsController.text.trim(),
      "link": _linkController.text.trim(),
      "image_url": mediaUrl,
      "type": _selectedVideo != null ? "video" : "image",
    });

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context, true);
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

            /// 🔥 TOPLULUK ARAMA (DAVRANIŞ AYNI)
            _isLoadingCommunities
                ? const Center(child: CircularProgressIndicator())
                : Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['name'],
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _communities;
                }
                return _communities.where((c) =>
                    c['name']
                        .toLowerCase()
                        .startsWith(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                setState(() {
                  _selectedCommunityId = selection['id'];
                });
              },
              fieldViewBuilder: (
                  context,
                  textEditingController,
                  focusNode,
                  onFieldSubmitted,
                  ) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Topluluk ara",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// 🔹 Başlık
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Başlık",
                border: InputBorder.none,
              ),
            ),
            const Divider(),

            /// 🔹 Etiket
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: "Etiketler",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Link
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: "Link",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Gövde
            TextField(
              controller: _bodyController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Gönderi içeriği",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Medya Önizleme
            if (_selectedImage != null || _selectedVideo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(
                      _selectedImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 200,
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(Icons.videocam, size: 60),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _removeMedia,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            /// 🔹 Alt ikonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
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
