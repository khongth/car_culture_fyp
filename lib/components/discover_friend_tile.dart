import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_provider.dart';
import '../models/user.dart';

class DiscoverFriendTile extends StatefulWidget {
  final String uid;
  final UserProfile user;
  final Function(String uid) onUserTap;

  const DiscoverFriendTile({
    super.key,
    required this.user,
    required this.uid,
    required this.onUserTap,
  });

  @override
  _DiscoverFriendTileState createState() => _DiscoverFriendTileState();
}

class _DiscoverFriendTileState extends State<DiscoverFriendTile> {
  late final DatabaseProvider databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    // Check if already following
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final isFollowing = await databaseProvider.isFollowing(widget.user.uid);
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<void> toggleFollow() async {
    if (_isFollowing) {
      await databaseProvider.unfollowUser(widget.user.uid);
    } else {
      await databaseProvider.followUser(widget.user.uid);
    }
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: widget.user.profileImageUrl.isNotEmpty
            ? NetworkImage(widget.user.profileImageUrl)  // Load the user's profile image
            : const AssetImage('assets/default_avatar.png') as ImageProvider,  // Default avatar if no image
      ),
      title: Text(
        widget.user.username,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.email,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14,
            ),
          ),
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.user.bio!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey : Colors.blue, // Change color based on follow state
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(_isFollowing ? 'Following' : 'Follow'),
      ),
      onTap: () => widget.onUserTap(widget.uid),  // Navigate to user profile on tap
    );
  }
}
