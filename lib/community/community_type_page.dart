import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import '../core/api_client.dart';
import '../home/home_page.dart';
//4
class CommunityTypePage extends StatefulWidget {
  final String name;
  final String description;
  final String? bannerUrl;
  final String? iconUrl;
  final List<String> selectedTopics;

  const CommunityTypePage({
    super.key,
    required this.name,
    required this.description,
    this.bannerUrl,
    this.iconUrl,
    required this.selectedTopics,
  });

  @override
  State<CommunityTypePage> createState() => _CommunityTypePageState();
}

class _CommunityTypePageState extends State<CommunityTypePage> {
  String communityType = "public"; // public, restricted, private
  bool isAdult = false;
  bool isLoading = false;

  Future<void> _finish() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiClient.dio.post(
        "/api/communities",
        data: {
          "name": widget.name,
          "description": widget.description,
          "topics": widget.selectedTopics
              .map((t) => t.toLowerCase())
              .toList(),
          "type": communityType,
          "isAdult": isAdult,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.community_created)),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.community_type_title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: isLoading ? null : _finish,
            child: isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(l10n.create, style: const TextStyle(fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(l10n.description_text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            Text(l10n.important_note,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildRadio(
              l10n.public_title,
              l10n.public_subtitle,
              "public",
              Icons.add_circle_outline,
            ),
            _buildRadio(
              l10n.restricted_title,
              l10n.restricted_subtitle,
              "restricted",
              Icons.remove_red_eye_outlined,
            ),
            _buildRadio(
              l10n.private_title,
              l10n.private_subtitle,
              "private",
              Icons.lock_outline,
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.adult_label,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Switch(
                  value: isAdult,
                  onChanged: (v) => setState(() => isAdult = v),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(String title, String subtitle, String value, IconData icon) {
    return InkWell(
      onTap: () => setState(() => communityType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Radio(
              value: value,
              groupValue: communityType,
              onChanged: (val) {
                setState(() => communityType = val!);
              },
            )
          ],
        ),
      ),
    );
  }
}

