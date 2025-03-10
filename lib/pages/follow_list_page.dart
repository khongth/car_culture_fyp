import 'package:car_culture_fyp/components/user_list_tile.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:car_culture_fyp/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FollowListPage extends StatefulWidget {
  final String uid;
  final Function(String uid) onUserTap;
  const FollowListPage({super.key, required this.uid, required this.onUserTap});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  UserProfile? user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    loadFollowerList();
    loadFollowingList();
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> loadFollowerList() async {
    user = await databaseProvider.userProfile(widget.uid);

    await databaseProvider.loadUserFollowersProfiles(widget.uid);
  }

  Future<void> loadFollowingList() async {
    await databaseProvider.loadUserFollowingProfiles(widget.uid);
  }

  @override
  Widget build(BuildContext context) {

    final followers = listeningProvider.getListOfFollowersProfile(widget.uid);
    final following = listeningProvider.getListOfFollowingProfile(widget.uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isLoading ? " " : user?.username ?? " ",
            style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          ),
          centerTitle: true,
          bottom: TabBar(
            dividerColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.inversePrimary,
            tabs: [
              Tab(text: "Followers"),
              Tab(text: "Following"),
            ]
          ),
        ),

        body: TabBarView(
          children: [
            _buildUserList(followers, "No followers"),
            _buildUserList(following, "No following"),
          ]
        ),
      )
    );
  }

  //Build user list
  Widget _buildUserList(List<UserProfile> userList, String emptyMessage) {
      return userList.isEmpty
        ? Center(child: Text(emptyMessage),)
        : ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];

          return UserListTile(user: user, uid: widget.uid, onUserTap: widget.onUserTap,);
        }
      );
  }
}
