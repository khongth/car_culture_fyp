import 'package:car_culture_fyp/components/user_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_provider.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  final Function(String uid) onUserTap;
  const SearchPage({super.key, this.onDrawerOpen, required this.onUserTap});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {

    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final listeningProvider = Provider.of<DatabaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search",
            border: InputBorder.none,
          ),

          onChanged: (value) {
            if(value.isNotEmpty) {
              databaseProvider.searchUsers(value);
            } else {
              databaseProvider.searchUsers("");
            }
          },
        ),

        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            if (widget.onDrawerOpen != null) {
              widget.onDrawerOpen!();
            }
          },
        ),
      ),
      body: listeningProvider.searchResult.isEmpty
          ? Center(child: Text("No users found"))
          :
          ListView.builder(
            itemCount: listeningProvider.searchResult.length,
            itemBuilder: (context, index) {
              final user = listeningProvider.searchResult[index];

              return UserListTile(user: user, uid: user.uid, onUserTap: widget.onUserTap,);
            })
    );
  }
}
