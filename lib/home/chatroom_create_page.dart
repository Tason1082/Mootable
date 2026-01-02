import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../community/topic_data.dart';



class ChatRoomCreatePage extends StatefulWidget {
  const ChatRoomCreatePage({super.key});

  @override
  State<ChatRoomCreatePage> createState() => _ChatRoomCreatePageState();
}

class _ChatRoomCreatePageState extends State<ChatRoomCreatePage> {
  String visibility = "Herkes";
  bool saveRoom = false;
  bool privateMode = false;

  /// Seçilen topic'ler
  final Set<String> selectedTopics = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    /// 🔥 topic_data.dart içindeki TÜM topic’ler
    final Map<String, List<String>> topicMap = getTopicsData(l10n);
    final List<String> allTopics =
    topicMap.values.expand((list) => list).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            const Text(
              "Sohbet Odanı oluştur",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            /// VISIBILITY DROPDOWN
            DropdownButtonFormField<String>(
              value: visibility,
              items: const [
                DropdownMenuItem(value: "Herkes", child: Text("Herkes")),
                DropdownMenuItem(value: "Takipçiler", child: Text("Takipçiler")),
              ],
              onChanged: (value) {
                setState(() {
                  visibility = value!;
                });
              },
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// QUESTION
            const Text(
              "Nelerden bahsetmek istiyorsun?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            /// TOPIC TITLE
            const Text(
              "Konu seç",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 TÜM TOPIC’LER (YAN YANA + SCROLL)
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: allTopics.map((topic) {
                    final bool isSelected =
                    selectedTopics.contains(topic);

                    return ChoiceChip(
                      label: Text(topic),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            selectedTopics.remove(topic);
                          } else {
                            selectedTopics.add(topic);
                          }
                        });
                      },
                      selectedColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.blue
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            /// SAVE ROOM SWITCH
            _switchTile(
              title: "Sohbet Odasını kaydet",
              value: saveRoom,
              onChanged: (val) {
                setState(() {
                  saveRoom = val;
                });
              },
            ),

            /// PRIVATE MODE SWITCH
            _switchTile(
              title: "Gizli moda izin ver",
              value: privateMode,
              onChanged: (val) {
                setState(() {
                  privateMode = val;
                });
              },
            ),

            const SizedBox(height: 16),

            /// START BUTTON
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4B5CFF),
                    Color(0xFF8A5CFF),
                  ],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  debugPrint("Visibility: $visibility");
                  debugPrint("Save Room: $saveRoom");
                  debugPrint("Private Mode: $privateMode");
                  debugPrint("Selected Topics: $selectedTopics");
                },
                child: const Text(
                  "Sohbet Odanı başlat",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.blue,
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}
