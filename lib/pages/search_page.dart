import 'package:car_culture_fyp/components/user_list_tile.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/database_provider.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  final Function(String uid) onUserTap;

  const SearchPage({
    super.key,
    this.onDrawerOpen,
    required this.onUserTap,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showResults = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      databaseProvider.clearSearchResults();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final listeningProvider = Provider.of<DatabaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: "Search user...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                // Clear results when search is empty
                databaseProvider.clearSearchResults();
              } else {
                // Clear previous results before searching
                databaseProvider.clearSearchResults();
                // Perform new search
                databaseProvider.searchUsers(value);
              }

              setState(() {
                _showResults = true;
              });
            },
          ),
        ),
        actions: [
          if (_showResults || _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _searchController.clear();
                  // Clear results when search is closed
                  databaseProvider.clearSearchResults();
                  FocusScope.of(context).unfocus();
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main list or empty state
          listeningProvider.searchResult.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
            itemCount: listeningProvider.searchResult.length,
            itemBuilder: (context, index) {
              final user = listeningProvider.searchResult[index];
              return UserListTile(
                user: user,
                uid: user.uid,
                onUserTap: widget.onUserTap,
              );
            },
          ),

          // Dropdown results
          if (_showResults && _searchController.text.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 4,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: listeningProvider.searchResult.isEmpty
                      ? const ListTile(
                    title: Text("No users found"),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: listeningProvider.searchResult.length,
                    itemBuilder: (context, index) {
                      final user = listeningProvider.searchResult[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl),
                        ),
                        title: Text(user.username),
                        subtitle: Text(user.email),
                        onTap: () {
                          widget.onUserTap(user.uid);
                          setState(() {
                            _showResults = false;
                            _searchController.text = user.username;
                            FocusScope.of(context).unfocus();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}