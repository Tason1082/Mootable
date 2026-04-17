import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import 'error/error_handler.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final imageCtrl = TextEditingController();

  String? gender;
  DateTime? birthDate;

  bool loading = true;
  bool saving = false;
  String? userId;

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
      imageCtrl.text = u['profileImageUrl'] ?? "";

      gender = u['gender'];

      birthDate = u['birthDate'] != null
          ? DateTime.tryParse(u['birthDate'])
          : null;

    } catch (e, st) {
      ErrorHandler.showError(context, e, stackTrace: st);
    }

    setState(() => loading = false);
  }

  Future<void> _save() async {
    setState(() => saving = true);

    final data = <String, dynamic>{};

    if (emailCtrl.text.trim().isNotEmpty)
      data["email"] = emailCtrl.text.trim();

    if (fullNameCtrl.text.trim().isNotEmpty)
      data["fullName"] = fullNameCtrl.text.trim();

    if (imageCtrl.text.trim().isNotEmpty)
      data["profileImageUrl"] = imageCtrl.text.trim();

    if (gender != null)
      data["gender"] = gender;


      data["birthDate"] = birthDate != null
          ? birthDate!.toUtc().toIso8601String()
          : null;

    await ApiClient.dio.put('/api/users', data: data);

    if (mounted) setState(() => saving = false);
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

            _input("E-posta", emailCtrl),
            _input("Ad Soyad", fullNameCtrl),
            _input("Profil Foto URL", imageCtrl),

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