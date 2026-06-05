import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_client.dart';
import 'comment_service.dart';

class CommentPage extends StatefulWidget {
  final int postId;

  final VoidCallback? onCommentAdded;
  const CommentPage({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  List<Map<String, dynamic>> comments = [];

  Map<int?, List<Map<String, dynamic>>> tree = {};
  int? replyingTo;

  final TextEditingController _replyController =
  TextEditingController();
  final _text = TextEditingController();

  /// replies açık/kapalı
  Map<int, bool> replyVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _text.dispose();
    _replyController.dispose();
    super.dispose();
  }
  List<Map<String, dynamic>> getAllReplies(int commentId) {
    List<Map<String, dynamic>> result = [];

    void collect(int id) {
      final children = tree[id] ?? [];

      for (final child in children) {
        result.add(child);
        collect(child["id"]);
      }
    }

    collect(commentId);

    return result;
  }
  Future<void> _fetchComments() async {
    try {
      final list = await CommentService.getComments(widget.postId);

      comments = list;

      tree = {};

      for (var c in comments) {
        final pid = c["parentCommentId"];

        tree.putIfAbsent(pid, () => []);

        tree[pid]!.add(c);
      }

      setState(() {});
    } catch (e) {
      debugPrint("FETCH COMMENTS ERROR: $e");
    }
  }
  Future<void> _addComment() async {
    final content = _text.text.trim();

    if (content.isEmpty) return;

    try {
      final success = await CommentService.addComment(
        widget.postId,
        content,
      );

      if (!success) {
        throw Exception("Comment failed");
      }

      _text.clear();

      widget.onCommentAdded?.call();

      await _fetchComments();

    } catch (e) {
      debugPrint("ADD COMMENT ERROR: $e");
    }
  }
  Future<void> _addReply(int parentId, String content) async {
    final text = content.trim();

    if (text.isEmpty) return;

    try {
      final success = await CommentService.addReply(
        widget.postId,
        parentId,
        text,
      );

      if (!success) {
        throw Exception("Reply failed");
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("ADD REPLY ERROR: $e");
    }
  }
  Future<void> _voteComment(int commentId, int vote) async {
    try {
      final success = await CommentService.vote(commentId, vote);

      if (!success) {
        throw Exception("Vote failed");
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("VOTE COMMENT ERROR: $e");
    }
  }
  Future<void> _editComment(int commentId, String content) async {
    try {
      final success = await CommentService.edit(commentId, content);

      if (!success) {
        throw Exception("Edit failed");
      }

      await _fetchComments();
    } catch (e) {
      debugPrint("EDIT COMMENT ERROR: $e");
    }
  }

  void _showReplyDialog(int parentId) {
    final replyText = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Yanıtla"),
          content: TextField(
            controller: replyText,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _addReply(
                  parentId,
                  replyText.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Gönder"),
            ),
          ],
        );
      },
    );
  }
  int getReplyCount(int commentId) {
    final children = tree[commentId] ?? [];

    int total = children.length;

    for (final child in children) {
      total += getReplyCount(child["id"]);
    }

    return total;
  }
  void _showEditDialog(
      int commentId,
      String oldContent,
      ) {
    final editor = TextEditingController(
      text: oldContent,
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Düzenle"),
          content: TextField(
            controller: editor,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final text = editor.text.trim();

                if (text.isNotEmpty) {
                  await _editComment(
                    commentId,
                    text,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
  Widget _buildComment(
      Map<String, dynamic> c,
      int depth,
      ) {
    final children = getAllReplies(c["id"]);

    final int commentId = c["id"];
    final bool showReplies =
        replyVisibility[commentId] ?? false;

    return Padding(
      padding: EdgeInsets.only(
        left: depth == 0 ? 0 : 20,
        top: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                c["profileImageUrl"] != null
                    ? NetworkImage(
                  c["profileImageUrl"],
                )
                    : null,
                child: c["profileImageUrl"] == null
                    ? const Icon(
                  Icons.person,
                  size: 18,
                )
                    : null,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      c["username"] ?? "Unknown",
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      c["content"] ?? "",
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color:
                            (c["userVote"] ??
                                0) ==
                                1
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          onPressed: () =>
                              _voteComment(
                                commentId,
                                1,
                              ),
                        ),

                        Text(
                          (c["netScore"] ?? 0)
                              .toString(),
                        ),

                        IconButton(
                          icon: Icon(
                            Icons
                                .arrow_downward,
                            size: 18,
                            color:
                            (c["userVote"] ??
                                0) ==
                                -1
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () =>
                              _voteComment(
                                commentId,
                                -1,
                              ),
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              replyingTo =
                              replyingTo ==
                                  commentId
                                  ? null
                                  : commentId;
                            });
                          },
                          child: const Text(
                            "Yanıtla",
                          ),
                        ),

                        if (c["isOwner"] == true)
                          TextButton(
                            onPressed: () =>
                                _showEditDialog(
                                  commentId,
                                  c["content"] ??
                                      "",
                                ),
                            child: const Text(
                              "Düzenle",
                            ),
                          ),
                      ],
                    ),

                    if (replyingTo == commentId)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                _replyController,
                                decoration:
                                InputDecoration(
                                  hintText:
                                  "Yanıt yaz...",
                                  border:
                                  OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.send,
                              ),
                              onPressed:
                                  () async {
                                await _addReply(
                                  commentId,
                                  _replyController
                                      .text,
                                );

                                _replyController
                                    .clear();

                                if (mounted) {
                                  setState(() {
                                    replyingTo =
                                    null;
                                    replyVisibility[
                                    commentId] =
                                    true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                    if (depth == 0 && children.isNotEmpty)
                      InkWell(
                        onTap: () {
                          setState(() {
                            replyVisibility[commentId] = !showReplies;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 1,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                showReplies
                                    ? "Yanıtları gizle"
                                    : "${getReplyCount(commentId)} yanıtı görüntüle",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (showReplies)
            ...children.map(
                  (reply) => Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  top: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: reply["profileImageUrl"] != null
                          ? NetworkImage(reply["profileImageUrl"])
                          : null,
                      child: reply["profileImageUrl"] == null
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reply["username"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(reply["content"] ?? ""),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = tree[null] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yorumlar"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var c in roots)
                  _buildComment(c, 0),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: "Yorum yaz...",
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

