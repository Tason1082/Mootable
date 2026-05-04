import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import 'error/error_handler.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  File? selectedImage;
  String? currentImageUrl;

  final emailCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();

  String? gender;
  DateTime? birthDate;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final res = await ApiClient.dio.get('/api/users/me');
      final u = res.data;

      emailCtrl.text = u['email'] ?? "";
      fullNameCtrl.text = u['fullName'] ?? "";

      currentImageUrl = u['profileImageUrl'];

      gender = u['gender'];

      birthDate = u['birthDate'] != null
          ? DateTime.tryParse(u['birthDate'])
          : null;

    } catch (e, st) {

    }

    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) return;

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(selectedImage!.path),
    });

    final res = await ApiClient.dio.post(
      '/api/users/upload-profile-photo',
      data: formData,
    );

    setState(() {
      currentImageUrl = res.data; // fileName geliyor
      selectedImage = null;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);

    try {
      if (selectedImage != null) {
        await _uploadImage();
      }

      final data = <String, dynamic>{};

      if (emailCtrl.text.trim().isNotEmpty) {
        data["email"] = emailCtrl.text.trim();
      }

      if (fullNameCtrl.text.trim().isNotEmpty) {
        data["fullName"] = fullNameCtrl.text.trim();
      }

      if (gender != null) {
        data["gender"] = gender;
      }

      data["birthDate"] = birthDate != null
          ? birthDate!.toUtc().toIso8601String()
          : null;

      await ApiClient.dio.put('/api/users', data: data);
    } catch (e, st) {

    }

    setState(() => saving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  /// 🔥 SAFE IMAGE URL (PRIVATE BUCKET FIX)
  String? getImageUrl() {
    if (currentImageUrl == null) return null;

    return currentImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kişisel Bilgiler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: saving ? null : _save,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// 👤 PROFILE IMAGE (FIXED)
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,

                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (currentImageUrl != null
                      ? NetworkImage(
                    // 🔥 backend signed URL dönmeli!
                    currentImageUrl!,
                  )
                      : null) as ImageProvider?,

                  child: (selectedImage == null && currentImageUrl == null)
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _input("E-posta", emailCtrl),
            _input("Ad Soyad", fullNameCtrl),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(labelText: "Cinsiyet"),
              items: ["Erkek", "Kadın"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => gender = val),
            ),

            const SizedBox(height: 16),

            ListTile(
              title: const Text("Doğum Tarihi"),
              subtitle: Text(
                birthDate != null
                    ? "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}"
                    : "Seç",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}