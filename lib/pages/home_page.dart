import 'dart:io';
import 'dart:ui';
import 'package:car_culture_fyp/components/post_input.dart';
import 'package:car_culture_fyp/components/post_tile.dart';
import 'package:car_culture_fyp/helper/navigatet_pages.dart';
import 'package:car_culture_fyp/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/database_provider.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;

  const HomePage({super.key, this.onDrawerOpen});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);

  final _messageController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadFollowingPosts(); // Force reload when dependencies change
  }

  @override
  void initState() {
    super.initState();
    loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    await databaseProvider.loadAllPosts();
  }

  Future<void> loadFollowingPosts() async {
    await databaseProvider.loadFollowingPosts();
  }

  void _showPostInputBox(BuildContext context, TextEditingController textController) {
    File? selectedImage; // ✅ Store the selected image

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          child: PostInputBox(
            textController: textController,
            hintText: "What's on your mind?",
            onImageSelected: (File? image) {
              selectedImage = image;
            },
            onPressed: () async {
              await postMessage(_messageController.text.trim(), selectedImage);
            },
            onPressedText: "Post",
          ),
        );
      },
    );
  }

  Future<void> postMessage(String message, File? imageFile) async {
    await databaseProvider.postMessage(message, imageFile: imageFile);
  }

  Future<void> _onRefresh() async {
    // Trigger the refresh of posts
    await loadAllPosts();
    await loadFollowingPosts();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              if (widget.onDrawerOpen != null) {
                widget.onDrawerOpen!();
              }
            },
          ),
          title: TabBar(
              dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0),
              unselectedLabelColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.inversePrimary,
              tabs: [
                Tab(text: "For you"),
                Tab(text: "Following"),
              ]
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => SearchPage(
                    onUserTap: (uid) => goUserPage(context, uid),
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ));
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,

        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(69, 123, 157, 1),
          shape: CircleBorder(),
          elevation: 0,
          highlightElevation: 0,
          onPressed: () => _showPostInputBox(context, _messageController),
          child: Icon(
            Icons.add,
          ),
        ),

        body: TabBarView(
            children: [
              _buildPostList(listeningProvider.allPosts),
              _buildPostList(listeningProvider.followingPosts),
            ]
        ),
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    return RefreshIndicator(
      onRefresh: _onRefresh, // Pull-to-refresh function
      child: posts.isEmpty
          ? Center(child: Text("Nothing here..."))
          : ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return PostTile(
            post: post,
            onUserTap: () => goUserPage(context, post.uid),
            onPostTap: () => goPostPage(context, post),
          );
        },
      ),
    );
  }
}
