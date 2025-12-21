import 'package:flutter/material.dart';

class QuotePostPage extends StatefulWidget {
  final Map post;
  const QuotePostPage({super.key, required this.post});

  @override
  State<QuotePostPage> createState() => _QuotePostPageState();
}

class _QuotePostPageState extends State<QuotePostPage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    /// 🔥 SAYFA AÇILIR AÇILMAZ KLAVYE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () {},
              child: const Text("Yeniden gönder"),
            ),
          ),
        ],
      ),

      /// ================= BODY =================
      body: SafeArea(
        child: Column(
          children: [
            /// YORUM ALANI
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Text("H")),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Yorum ekle...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// POST ALANI
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        dense: keyboardOpen,
                        leading: const CircleAvatar(),
                        title: Text(
                          widget.post["community_name"] ?? "",
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(widget.post["created_at"] ?? ""),
                      ),

                      /// ✅ GERÇEK KÜÇÜLEN RESİM (KIRPMA YOK)
                      if (widget.post["image_url"] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AnimatedScale(
                            scale: keyboardOpen ? 0.6 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.post["image_url"],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.post["content"] ?? "",
                          maxLines: keyboardOpen ? 3 : null,
                          overflow:
                          keyboardOpen ? TextOverflow.ellipsis : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// ================= ALT BAR =================
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: keyboardOpen ? 48 : 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  onPressed: () {},
                ),
                const Spacer(),
                const Icon(Icons.add_circle_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

