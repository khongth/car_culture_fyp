import 'package:car_culture_fyp/pages/home_page.dart';
import 'package:car_culture_fyp/pages/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/bottom_navigation_bar.dart';
import '../models/marketplace.dart';
import '../models/post.dart';
import '../pages/account_settings_page.dart';
import '../pages/blocked_users_page.dart';
import '../pages/post_page.dart';

void goUserPage(BuildContext context, String uid) {
  final bottomNavState = context.findAncestorStateOfType<BottomNavWrapperState>();
  if (bottomNavState != null) {
    bottomNavState.openProfilePage(uid);
  }
}

void goPostPage(BuildContext context, Post post) {
  final bottomNavState = context.findAncestorStateOfType<BottomNavWrapperState>();
  if (bottomNavState != null) {
    bottomNavState.openPostPage(post);
  }
}

void goBlockedUsersPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BlockedUsersPage(),
    ),
  );
}

void goAccountSettingsPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AccountSettingsPage(),
    ),
  );
}

void goMarketplaceItemPage(BuildContext context, MarketplacePost post) {
  final bottomNavState = context.findAncestorStateOfType<BottomNavWrapperState>();
  if (bottomNavState != null) {
    bottomNavState.openMarketplaceItemPage(post);
  }
}
