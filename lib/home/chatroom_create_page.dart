import 'package:flutter/material.dart';
import '../core/api_client.dart';


class ChatRoomCreatePage extends StatefulWidget {
  const ChatRoomCreatePage({super.key});

  @override
  State<ChatRoomCreatePage> createState() => _ChatRoomCreatePageState();
}

class _ChatRoomCreatePageState extends State<ChatRoomCreatePage> {
  String visibility = "Herkes";
  bool saveRoom = false;
  bool privateMode = false;

  bool loading = true;

  /// Backend’den gelen kategoriler
  List<Map<String, dynamic>> categories = [];

  /// Seçilen topic key'leri
  final Set<String> selectedTopicKeys = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final locale =
          Localizations.localeOf(context).languageCode;

      final response = await ApiClient.dio.get(
        "/api/categories",
        queryParameters: {"locale": locale},
      );

      setState(() {
        categories =
        List<Map<String, dynamic>>.from(response.data);
        loading = false;
      });
    } catch (e) {
      setState(() {
        categories = [];
        loading = false;
      });
    }
  }


  /// Tüm topic’leri tek liste yapıyoruz
  List<Map<String, dynamic>> get allTopics {
    return categories
        .expand((cat) =>
    List<Map<String, dynamic>>.from(cat["topics"] ?? []))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
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

            /// VISIBILITY
            DropdownButtonFormField<String>(
              value: visibility,
              items: const [
                DropdownMenuItem(
                    value: "Herkes",
                    child: Text("Herkes")),
                DropdownMenuItem(
                    value: "Takipçiler",
                    child: Text("Takipçiler")),
              ],
              onChanged: (value) {
                setState(() {
                  visibility = value!;
                });
              },
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Nelerden bahsetmek istiyorsun?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Konu seç",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 BACKEND TOPIC LISTESİ
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                  allTopics.map((topic) {
                    final key =
                    topic["key"].toString();
                    final name =
                    topic["name"].toString();

                    final isSelected =
                    selectedTopicKeys
                        .contains(key);

                    return ChoiceChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            selectedTopicKeys
                                .remove(key);
                          } else {
                            selectedTopicKeys
                                .add(key);
                          }
                        });
                      },
                      selectedColor:
                      Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.blue
                            : Colors.black,
                        fontWeight:
                        FontWeight.w600,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey
                              .shade300,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            /// SAVE ROOM
            _switchTile(
              title: "Sohbet Odasını kaydet",
              value: saveRoom,
              onChanged: (val) {
                setState(() {
                  saveRoom = val;
                });
              },
            ),

            /// PRIVATE MODE
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
                borderRadius:
                BorderRadius.circular(30),
                gradient:
                const LinearGradient(
                  colors: [
                    Color(0xFF4B5CFF),
                    Color(0xFF8A5CFF),
                  ],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  Colors.transparent,
                  shadowColor:
                  Colors.transparent,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(30),
                  ),
                ),
                onPressed: () {
                  debugPrint(
                      "Visibility: $visibility");
                  debugPrint(
                      "Save Room: $saveRoom");
                  debugPrint(
                      "Private Mode: $privateMode");
                  debugPrint(
                      "Selected Topic Keys: $selectedTopicKeys");

                  /// 🚀 Burada backend'e gönderilecek olan
                  /// topic key listesi: selectedTopicKeys
                },
                child: const Text(
                  "Sohbet Odanı başlat",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
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

