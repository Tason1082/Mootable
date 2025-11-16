import 'package:flutter/material.dart';
import 'topic_data.dart';
import 'community_type_page.dart';

class TopicSelectionPage extends StatefulWidget {
  const TopicSelectionPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Topluluk konularını seç"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: selectedTopics.isNotEmpty
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityTypePage(
                    name: "",
                    description: "",
                    selectedTopics: selectedTopics,
                  ),
                ),
              );
            }
                : null,
            child: const Text("Sonraki"),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "İlgilenen kullanıcıların topluluğunu bulmasına yardımcı olmak için en fazla 3 konu başlığı ekle.",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 16),

            Text(
              "${selectedTopics.length}/3 Konu",
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade400,
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

