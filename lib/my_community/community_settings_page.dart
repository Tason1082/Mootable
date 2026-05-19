import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';

class CommunitySettingsPage extends StatefulWidget {
  final Map<String, dynamic> community;
  final Future<void> Function() onUpdated;
  final Function(String newName) onNameChanged;
  const CommunitySettingsPage({
    super.key,
    required this.community,
    required this.onUpdated,
    required this.onNameChanged,
  });
  @override
  State<CommunitySettingsPage> createState() =>
      _CommunitySettingsPageState();
}

class _CommunitySettingsPageState
    extends State<CommunitySettingsPage> {

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController topicsController;

  late String selectedType;
  late bool isAdult;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.community['name'] ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.community['description'] ?? '',
    );

    topicsController = TextEditingController(
      text: (widget.community['topics'] as List?)
          ?.join(", ") ??
          '',
    );

    selectedType =
        widget.community['type'] ?? 'public';

    isAdult =
        widget.community['isAdult'] ?? false;
  }

  Future<void> updateCommunity() async {
    try {
      setState(() {
        loading = true;
      });

      final topics = topicsController.text
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final body = {
        "name": nameController.text.trim(),
        "description":
        descriptionController.text.trim(),
        "topics": topics,
        "type": selectedType,
        "isAdult": isAdult,
      };

      final response = await ApiClient.dio.put(
        "/api/communities/${widget.community['id']}",
        data: body,
      );

      final data = response.data;

      if (data["success"] != true) {
        throw Exception(data["message"]);
      }
      final updated = data["data"];

      widget.community["name"] =
      updated["name"];

      widget.community["description"] =
      updated["description"];

      widget.community["topics"] =
      updated["topics"];

      widget.community["type"] =
      updated["type"];

      widget.community["isAdult"] =
      updated["isAdult"];
      widget.onNameChanged(
          updated["name"]);
      await widget.onUpdated();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Topluluk güncellendi"),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluk Ayarları"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Topluluk adı",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Açıklama",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: topicsController,
              decoration: const InputDecoration(
                labelText: "Konular",
                hintText: "flutter, teknoloji, oyun",
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedType,

              decoration: const InputDecoration(
                labelText: "Topluluk Türü",
              ),

              items: const [

                DropdownMenuItem(
                  value: "public",
                  child: Text("Public"),
                ),

                DropdownMenuItem(
                  value: "private",
                  child: Text("Private"),
                ),

                DropdownMenuItem(
                  value: "restricted",
                  child: Text("Restricted"),
                ),
              ],

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              value: isAdult,

              onChanged: (value) {
                setState(() {
                  isAdult = value;
                });
              },

              title: const Text("18+ İçerik"),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                loading
                    ? null
                    : updateCommunity,

                child:
                loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text("Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}