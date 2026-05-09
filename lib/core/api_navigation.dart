import 'package:flutter/material.dart';

class AppNavigation {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static int? pendingPostId;

  static void openPostInFeed(int postId) {
    pendingPostId = postId;

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );
  }
}