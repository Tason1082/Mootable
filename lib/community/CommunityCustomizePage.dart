import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'topic_selection_page.dart';

class CommunityCustomizePage extends StatefulWidget {
  final String name;
  final String description;

  const CommunityCustomizePage({
    super.key,
    required this.name,
    required this.description,
  });

  @override
  State<CommunityCustomizePage> createState() =>
      _CommunityCustomizePageState();
}

class _CommunityCustomizePageState extends State<CommunityCustomizePage> {
  File? bannerImage;
  File? iconImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBanner() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        bannerImage = File(picked.path);
      });
    }
  }

  Future<void> _pickIcon() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        iconImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.community_customize_title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicSelectionPage(
                    name: widget.name,
                    description: widget.description,
                    bannerUrl: bannerImage?.path,
                    iconUrl: iconImage?.path,
                  ),
                ),
              );
            },
            child: Text(
              l10n.next_button,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.preview_text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),

            Text(
              l10n.preview_label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            /// REDDIT TARZI PREVIEW
            SizedBox(
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  /// BANNER
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[300],
                      image: bannerImage != null
                          ? DecorationImage(
                        image: FileImage(bannerImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                  ),

                  /// ICON (YUVARLAK – REDDIT GİBİ)
                  Positioned(
                    left: 16,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey[400],
                        backgroundImage:
                        iconImage != null ? FileImage(iconImage!) : null,
                        child: iconImage == null
                            ? const Icon(
                          Icons.group,
                          size: 32,
                          color: Colors.white,
                        )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// BANNER SEÇ
            Text(l10n.banner_label, style: const TextStyle(fontSize: 16)),
            Text(l10n.banner_ratio),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickBanner,
              child: Text(l10n.add_button),
            ),

            const SizedBox(height: 20),

            /// ICON SEÇ
            Text(l10n.icon_label, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickIcon,
              child: Text(l10n.add_button),
            ),
          ],
        ),
      ),
    );
  }
}

