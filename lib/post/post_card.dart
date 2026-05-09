import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../TimeAgo.dart';
import '../chat/conversation_service.dart';
import '../comment/comment_page.dart';
import '../core/api_client.dart';


import '../core/api_service.dart';
import '../my_community/community_detail_page.dart';
import '../newchatpage.dart';
import '../profile_page.dart';
import '../quote_post_page.dart';
import 'editpost_page.dart';
import 'full_screen_image.dart';
import 'inline_video_player.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final BuildContext parentContext;


  final void Function(int postId, int vote)? onVote;
  final void Function(String communityName, int index)? onJoinCommunity;
  final bool isMyPost;
  final bool highlighted;
  final VoidCallback? onDeleted;
  final GlobalKey? postKey;
  final bool highlight;
  const PostCard({
    super.key,
    required this.post,
    required this.parentContext,
    this.onVote,
    this.onJoinCommunity,
    this.isMyPost = false,
    this.highlighted = false,
    this.onDeleted,
    this.postKey,
    this.highlight = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isSaved = false;
  bool _loadingSaved = true;
  List<UserDto> _users = [];
  List<UserDto> _filteredUsers = [];
  bool _loadingUsers = false;
  bool _isJoined = false;
  bool _loadingJoin = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _currentIndex = 0; // 🔥 carousel index

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _checkIfJoined();
  }
  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);

    final users = await ApiService.getUsers();

    if (!mounted) return;

    setState(() {
      _users = users;
      _filteredUsers = users;
      _loadingUsers = false;
    });
  }

  String extractStoragePath(String url) {
    final uri = Uri.parse(url);

    final path = uri.path;

    final parts = path.split('/posts/');

    if (parts.length > 1) {
      return parts[1];
    }

    return url;
  }
  Future<void> _sendPostToUser(UserDto user) async {
    try {
      final conversationId = await ConversationService.create(
        userIds: [user.id],
      );

      final medias = widget.post["medias"] as List<dynamic>? ?? [];

      final firstMedia = medias.isNotEmpty ? medias.first : null;

      final mediaUrl = firstMedia != null ? firstMedia["url"] : null;
      final mediaType = firstMedia != null ? firstMedia["type"] : null;

      final payload = {
        "conversationId": conversationId,
        "content": widget.post["content"],
        "receiverId": user.id,
        "medias": firstMedia != null
            ? [
          {
            "url": extractStoragePath(firstMedia["url"]),
            "type": firstMedia["type"],
          }
        ]
            : [],
      };



      await ConversationService.sendMessage(
        conversationId: conversationId,
        content: payload["content"],
        receiverId: user.id,
        medias: List<Map<String, dynamic>>.from(payload["medias"]),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.username} kullanıcısına gönderildi"),
        ),
      );
    } catch (e) {
      debugPrint("SEND POST ERROR: $e");
    }
  }






  // ================= SAVE =================
  Future<void> _checkIfSaved() async {
    final postId = int.parse(widget.post["id"].toString());

    try {
      final res = await ApiClient.dio.get(
        '/api/posts/save/is_saved/$postId',
      );

      // 🔥 ApiResponse kontrolü
      if (res.data["success"] == false) {
        throw Exception(res.data["message"]);
      }

      final isSaved = res.data["data"]["isSaved"] ?? false;

      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _loadingSaved = false;
        });
      }
    } catch (e) {
      debugPrint("CHECK SAVE ERROR: $e");

      if (mounted) {
        setState(() => _loadingSaved = false);
      }
    }
  }
  Future<void> _toggleSave() async {
    if (_loadingSaved) return;

    final postId = int.parse(widget.post["id"].toString());
    final previous = _isSaved;

    // ⚠️ optimistic UI (sadece loading için)
    setState(() {
      _loadingSaved = true;
    });

    try {
      final res = await ApiClient.dio.post(
        '/api/posts/save',
        data: {"postId": postId},
      );

      if (res.data["success"] == false) {
        throw Exception(res.data["message"]);
      }

      final saved = res.data["data"]["saved"] ?? false;

      // 🔥 TEK GERÇEK SOURCE OF TRUTH
      if (mounted) {
        setState(() {
          _isSaved = saved;
        });
      }

    } catch (e) {
      debugPrint("TOGGLE SAVE ERROR: $e");

      // rollback
      if (mounted) {
        setState(() {
          _isSaved = previous;
        });
      }

    } finally {
      if (mounted) {
        setState(() {
          _loadingSaved = false;
        });
      }
    }
  }
  // ================= JOIN =================
  Future<void> _checkIfJoined() async {
    final communityId = widget.post["communityId"]?.toString();
    if (communityId == null) return;

    try {
      final joined = await ApiService.isJoined(communityId);

      if (mounted) {
        setState(() {
          _isJoined = joined;
          _loadingJoin = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingJoin = false);
    }
  }

  Future<void> _toggleJoin() async {
    final communityId = widget.post["communityId"]?.toString();

    if (communityId == null) return;

    setState(() {
      _loadingJoin = true;
    });

    final oldState = _isJoined;

    try {
      if (_isJoined) {
        await ApiService.leaveCommunity(communityId);
      } else {
        await ApiService.joinCommunity(communityId);
      }

      if (!mounted) return;

      setState(() {
        _isJoined = !_isJoined;
      });
    } catch (e) {
      _isJoined = oldState;

      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text("İşlem başarısız")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingJoin = false;
        });
      }
    }
  }
  // ================= MEDIA =================
  Widget _buildMedia(List medias) {
    if (medias.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: medias.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final media = medias[index];
              final url = media["url"];
              final type = media["type"];

              if (url == null) return const SizedBox.shrink();

              // VIDEO
              if (type == "video") {
                return InlineVideoPlayer(url: url);
              }

              // IMAGE
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(imageUrl: url),
                    ),
                  );
                },
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),

        if (medias.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(medias.length, (index) {
              return Container(
                margin: const EdgeInsets.all(3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.black
                      : Colors.grey,
                ),
              );
            }),
          ),
      ],
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final postId = post["id"];
    final medias = post["medias"] as List<dynamic>? ?? [];
    final profileImage = post["profileImageUrl"];

    return Container(
        key: widget.postKey,
        color: Colors.white,

        child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),

    color: widget.highlight
    ? Colors.yellow.withOpacity(0.25)
        : Colors.white,

    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

          // ================= HEADER =================
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImage != null &&
                  profileImage.toString().isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null ||
                  profileImage.toString().isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          username: post["username"],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    post["username"] ?? "user",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                GestureDetector(
                  onTap: () {
                    if (post["community"] == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityDetailPage(
                          communityName: post["community"],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    post["community"] ?? "",
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              ],
            ),

            subtitle: Text(
              post["created_at"] != null
                  ? TimeAgo.format(
                context,
                DateTime.parse(post["created_at"]),
              )
                  : "",
            ),

            trailing: _loadingJoin
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : (!_isJoined
                ? TextButton(
              onPressed: _toggleJoin,
              child: const Text("Katıl"),
            )
                : const SizedBox.shrink()),
          ),

          // ================= MEDIA =================
          if (medias.isNotEmpty) _buildMedia(medias),

          // ================= CONTENT =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(post["content"] ?? ""),
          ),

          // ================= ACTIONS =================
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: post["user_vote"] == 1
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                onPressed: () =>
                    widget.onVote?.call(postId, 1),
              ),

              Text("${post["votes_count"] ?? 0}"),

              IconButton(
                icon: Icon(
                  Icons.arrow_downward,
                  color: post["user_vote"] == -1
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
                onPressed: () =>
                    widget.onVote?.call(postId, -1),
              ),

              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () {
                  Navigator.push(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (_) =>
                          CommentPage(postId: postId),
                    ),
                  );
                },
              ),

              Text("${post["commentCount"] ?? 0}"),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  await _loadUsers();

                  if (!mounted) return;

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) {
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Column(
                              children: [

                                const SizedBox(height: 12),

                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Gönder",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // SEARCH
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    onChanged: (value) {
                                      setModalState(() {
                                        _filteredUsers = _users.where((u) {
                                          return u.username
                                              .toLowerCase()
                                              .contains(value.toLowerCase());
                                        }).toList();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Kullanıcı ara...",
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Expanded(
                                  child: _loadingUsers
                                      ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                      : ListView.builder(
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (_, index) {
                                      final user = _filteredUsers[index];

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                          user.profileImageUrl != null
                                              ? NetworkImage(
                                            user.profileImageUrl!,
                                          )
                                              : null,
                                          child: user.profileImageUrl == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),

                                        title: Text(user.username),

                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            _sendPostToUser(user);
                                          },
                                          child: const Text("Gönder"),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const Spacer(),



              // ================= SAVE + 3 DOT =================
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _toggleSave,
                    icon: Icon(
                      _isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                  ),

                  if (widget.isMyPost)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == "edit") {
                          // EDIT PAGE
                        }

                        if (value == "delete") {
                          final confirm =
                          await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Post sil"),
                              content:
                              const Text("Emin misin?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, false),
                                  child: const Text("İptal"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context, true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final success =
                          await ApiService.deletePost(
                              post["id"]);

                          if (success && mounted) {
                            widget.onDeleted?.call();
                          }
                        }
                        if (value == "edit") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPostPage(post: post),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "edit",
                          child: Text("Düzenle"),
                        ),
                        PopupMenuItem(
                          value: "delete",
                          child: Text("Sil"),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),

          const Divider(),
        ],
      ),
        ),
    );
  }}