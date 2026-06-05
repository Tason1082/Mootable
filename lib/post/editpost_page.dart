import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../core/api_service.dart';

class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostPage({
    super.key,
    required this.post,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController linkController;
  late TextEditingController communityController;
  late TextEditingController tagsController;
  List<dynamic> communities = [];

  String? selectedCommunityId;
  File? selectedMedia;
  bool isVideo = false;

  bool loading = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final post = widget.post;

    titleController =
        TextEditingController(text: post["title"] ?? "");

    contentController =
        TextEditingController(text: post["content"] ?? "");

    linkController =
        TextEditingController(text: post["link"] ?? "");

    communityController =
        TextEditingController(text: post["communityName"] ?? "");

    tagsController = TextEditingController(
      text: (post["tags"] ?? []).join(", "),
    );
    loadCommunities(); // EKLE
  }

  // ================= PICK IMAGE =================
  bool communitiesLoaded = false;

  Future<void> loadCommunities() async {
    final data = await ApiService.getMyCommunities();

    setState(() {
      communities = data;

      final currentCommunityName =
      widget.post["communityName"];

      final selected =
      communities.cast<Map<String, dynamic>>().firstWhere(
            (x) => x["name"] == currentCommunityName,
        orElse: () => {},
      );

      if (selected.isNotEmpty) {
        selectedCommunityId = selected["id"];
      }
    });
  }
  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        selectedMedia = File(picked.path);
        isVideo = false;
      });
    }
  }

  // ================= PICK VIDEO =================

  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        selectedMedia = File(picked.path);
        isVideo = true;
      });
    }
  }

  // ================= UPDATE POST =================

  Future<void> updatePost() async {
    setState(() => loading = true);

    try {
      final formDataMap = {
        "title": titleController.text,
        "content": contentController.text,

        if (linkController.text.isNotEmpty)
          "link": linkController.text,

        if (selectedCommunityId != null)
          "communityId": selectedCommunityId,

        // BACKEND string[] bekliyorsa
        "tags": tagsController.text
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };

      // ================= MEDIA =================

      if (selectedMedia != null) {
        final fileName =
            selectedMedia!.path.split('/').last;

        formDataMap["files"] =
        await MultipartFile.fromFile(
          selectedMedia!.path,
          filename: fileName,
        );

        formDataMap["mediaType"] =
        isVideo ? "video" : "image";
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await ApiClient.dio.put(
        "/api/posts/${widget.post["id"]}",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
        ),
      );

      debugPrint("UPDATE RESPONSE: ${response.data}");

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("EDIT ERROR: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // ================= FIELD =================

  Widget field(
      String label,
      TextEditingController c, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        actions: [
          TextButton(
            onPressed: loading ? null : updatePost,
            child: const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ================= MEDIA PREVIEW =================

            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: selectedMedia != null
                  ? ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: isVideo
                    ? const Center(
                  child: Icon(
                    Icons.videocam,
                    size: 70,
                  ),
                )
                    : Image.file(
                  selectedMedia!,
                  fit: BoxFit.cover,
                ),
              )
                  : const Center(
                child: Text(
                  "No media selected",
                ),
              ),
            ),

            // ================= BUTTONS =================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Image"),
                ),

                const SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: pickVideo,
                  icon: const Icon(Icons.video_call),
                  label: const Text("Video"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= FIELDS =================

            field("Title", titleController),

            field(
              "Content",
              contentController,
              maxLines: 5,
            ),

            field("Link", linkController),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child:DropdownButtonFormField<String>(
                onTap: () {
                  loadCommunities();
                },
                value: selectedCommunityId,
                decoration: const InputDecoration(
                  labelText: "Community",
                  border: OutlineInputBorder(),
                ),
                items: communities.map((c) {
                  return DropdownMenuItem<String>(
                    value: c["id"],
                    child: Text(c["name"]),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCommunityId = value;
                  });
                },
              ),
            ),

            field(
              "Tags (comma separated)",
              tagsController,
            ),

            const SizedBox(height: 20),

            if (loading)
              const CircularProgressIndicator(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}