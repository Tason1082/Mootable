import 'package:flutter/material.dart';
import '../home/home_page.dart';

class AppNavigation {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static int? pendingPostId;

  static void openPostInFeed(int postId) {
    pendingPostId = postId;

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
          (route) => false,
    );
  }
}