import 'package:car_culture_fyp/auth/auth_cubit.dart';
import 'package:car_culture_fyp/components/bio_box.dart';
import 'package:car_culture_fyp/components/follow_button.dart';
import 'package:car_culture_fyp/components/post_tile.dart';
import 'package:car_culture_fyp/components/profile_stats.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import '../components/bio_input.dart';
import '../helper/navigatet_pages.dart';
import 'follow_list_page.dart';

class ProfilePage extends StatefulWidget {

  final String uid;
  final VoidCallback onClose;
  final Function(String uid) onUserTap;

  const ProfilePage({super.key, required this.uid, required this.onClose, required this.onUserTap});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  
  final _bioTextController = TextEditingController();
  
  UserProfile? user;
  String? currentUserId;

  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();

    final authCubit = context.read<AuthCubit>();
    currentUserId = authCubit.state.user?.uid;

    loadUser();
  }

  Future<void> loadUser() async {
    user = await databaseProvider.userProfile(widget.uid);

    await databaseProvider.loadUserFollowers(widget.uid);
    await databaseProvider.loadUserFollowing(widget.uid);

    _isFollowing = databaseProvider.isFollowing(widget.uid);

    setState(() {
      _isLoading = false;
    });
  }

  void _showEditBioBox(BuildContext context, TextEditingController bioTextController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return BioInputBox(
              textController: bioTextController, // Pass bio controller
              hintText: "Enter your bio...",
              onPressed: saveBio, // Close modal after saving
              onPressedText: "Save",
            );
          },
        );
      },
    );
  }

  Future<void> saveBio() async {
    setState(() {
      _isLoading = true;
    });

    await databaseProvider.updateBio(_bioTextController.text);
    user = await databaseProvider.userProfile(widget.uid);

    loadUser();

    setState(() {
      _isLoading = true;
    });
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

    //Get user posts
    final allUserPosts = listeningProvider.filterUserPosts(widget.uid);

    final followerCount = listeningProvider.getFollowerCount(widget.uid);
    final followingCount = listeningProvider.getFollowingCount(widget.uid);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.tertiary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_isLoading ? ' ' : user!.username),
        centerTitle: true,
        titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 24
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image(
                  image: NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
                  height: 100,
                  width: 100,
                ),
              )
            ),
          ),
          Center(
            child: Text(_isLoading ? ' ' : user!.email)
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                  child: MyBioBox(text: _isLoading ? '...' : user!.bio),
              ),
              if (user != null && user!.uid == currentUserId)
                Container(
                  padding: EdgeInsets.all(25),
                    child: GestureDetector(
                      onTap: () => _showEditBioBox(context, _bioTextController),
                      child: Icon(
                        IconlyLight.edit_square,
                        size: 18,
                      ),
                    ),
                )
            ],
          ),

          ProfileStats(
              postCount: allUserPosts.length,
              followerCount: followerCount,
              followingCount: followingCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FollowListPage(uid: widget.uid, onUserTap: widget.onUserTap),
                ),
              ),
          ),

          if (user!=null && user!.uid != currentUserId)
            Row(
              children: [
                Expanded(
                  child: FollowButton(
                      isFollowing: _isFollowing,
                      onPressed: toggleFollow,
                  ),
                ),
                Expanded(
                  child: FollowButton(
                      isFollowing: false,
                      onPressed: () {}
                  ),
                ),
              ],
            ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Consistent padding
            child: Center(
              child: Text(
                "Posts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ),

          Divider(
            thickness: 1,
            color: Theme.of(context).colorScheme.secondary,
          ),
          
          allUserPosts.isEmpty ?
              const Center(
                child: Text(
                  "No posts yet...",
                ),
              )
              : ListView.builder(
                  itemCount: allUserPosts.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    //Get each individual post
                    final post = allUserPosts[index];

                    return PostTile(
                      post: post,
                      onUserTap: () {},
                      onPostTap: () => goPostPage(context, post),
                    );
                  },
          ),
        ],
      )
    );
  }
}

