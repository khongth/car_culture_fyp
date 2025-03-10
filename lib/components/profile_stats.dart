import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;
  final VoidCallback? onTap;

  const ProfileStats({
    super.key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat(postCount, "posts", context, null),
          _buildStat(followerCount, "followers", context, onTap),
          _buildStat(followingCount, "following", context, onTap),
        ],
      ),
    );
  }

  Widget _buildStat(int count, String label, BuildContext context, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
