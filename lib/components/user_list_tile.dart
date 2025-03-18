import 'package:car_culture_fyp/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_provider.dart';

class UserListTile extends StatefulWidget {
  final String uid;
  final UserProfile user;
  final Function(String uid) onUserTap;

  const UserListTile({super.key, required this.user, required this.uid, required this.onUserTap});

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {

  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  String? currentUserId;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleFollow() async {
    if (_isFollowing) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Unfollow"),
            content: Text("Are you sure you want to unfollow?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel")
              ),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    await databaseProvider.unfollowUser(widget.uid);

                    setState(() {
                      _isFollowing = !_isFollowing;
                    });

                    await databaseProvider.loadUserFollowers(widget.uid);
                  },
                  child: Text("Unfollow")
              ),
            ],
          )
      );
    } else {
      await databaseProvider.followUser(widget.uid);

      setState(() {
        _isFollowing = !_isFollowing;
      });
      await databaseProvider.loadUserFollowers(widget.uid);
    }
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
        widget.user.email,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      subtitle: Text(
        '@${widget.user.username}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14,
        ),
      ),
      onTap: () => widget.onUserTap(widget.uid),  // Navigate to user profile on tap
    );
  }
}
