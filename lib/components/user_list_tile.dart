import 'package:car_culture_fyp/models/user.dart';
import 'package:car_culture_fyp/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_cubit.dart';
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

  //UserProfile? user;
  String? currentUserId;

  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();

    //final authCubit = context.read<AuthCubit>();
    //currentUserId = authCubit.state.user?.uid;

    //loadUser();
  }

  /*
  Future<void> loadUser() async {
    user = await databaseProvider.userProfile(widget.uid);

    await databaseProvider.loadUserFollowers(widget.uid);
    await databaseProvider.loadUserFollowing(widget.uid);

    _isFollowing = databaseProvider.isFollowing(widget.uid);

    setState(() {
      _isLoading = false;
    });
  }

   */

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
        backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
        /*
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                   */
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

      onTap: () => widget.onUserTap(widget.uid),
      /*
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(_isFollowing ? 'Follow' : 'Unfollow'),
      ),
     */
    );
  }
}
