import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'topic_data.dart';
import 'community_type_page.dart'; // Bu dosyan senin zaten mevcut
//3
class TopicSelectionPage extends StatefulWidget {
  final String name;
  final String description;
  final String? bannerUrl;
  final String? iconUrl;

  const TopicSelectionPage({
    super.key,
    required this.name,
    required this.description,
    this.bannerUrl,
    this.iconUrl,
  });

  @override
  State<TopicSelectionPage> createState() => _TopicSelectionPageState();
}

class _TopicSelectionPageState extends State<TopicSelectionPage> {
  final List<String> selectedTopics = [];

  void toggleTopic(String topic) {
    setState(() {
      if (selectedTopics.contains(topic)) {
        selectedTopics.remove(topic);
      } else if (selectedTopics.length < 3) {
        selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topicsData = getTopicsData(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.topic_selection_title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: selectedTopics.isNotEmpty
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityTypePage(
                    name: widget.name,
                    description: widget.description,
                    bannerUrl: widget.bannerUrl,
                    iconUrl: widget.iconUrl,
                    selectedTopics: selectedTopics,
                  ),
                ),
              );
            }
                : null,
            child: Text(l10n.next_button),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(l10n.topic_instruction, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            Text(
              l10n.topic_count(selectedTopics.length),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: selectedTopics.map((t) {
                return Chip(
                  label: Text(t),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => toggleTopic(t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ...topicsData.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: entry.value.map((topic) {
                      final isSelected = selectedTopics.contains(topic);
                      return ChoiceChip(
                        label: Text(topic),
                        selected: isSelected,
                        onSelected: (_) => toggleTopic(topic),
                        selectedColor: Colors.grey.shade300,
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

