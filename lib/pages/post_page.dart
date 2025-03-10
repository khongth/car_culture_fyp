import 'package:car_culture_fyp/components/bottom_navigation_bar.dart';
import 'package:car_culture_fyp/components/comment_tile.dart';
import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../components/comment_input.dart';
import '../helper/navigatet_pages.dart';
import '../models/post.dart';

class PostPage extends StatefulWidget {
  final Post post;
  final VoidCallback onClose;

  const PostPage({
    super.key,
    required this.post,
    required this.onClose
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  final _commentController = TextEditingController();

  void _openNewCommentBox() {
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
          child: CommentInputBox(
            textController: _commentController,
            post: widget.post,
            onPressed: () async {
              await _addComment();
            },
            onPressedText: "Post",
          ),
        );
      },
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await databaseProvider.addComment(widget.post.id, _commentController.text.trim());
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to all comments for this post
    final allComments = listeningProvider.getComments(widget.post.id);

    DateTime localTime = widget.post.timestamp.toDate().toLocal();
    String formattedTimestamp = DateFormat('hh:mm a · MMM d, yyyy').format(localTime);


    bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(widget.post.id);
    int likeCount = listeningProvider.getLikeCount(widget.post.id);
    int commentCount = allComments.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Post"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onClose, // Close post on back press
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Post Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: () => goUserPage(context, widget.post.uid),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Username & Email
                  GestureDetector(
                    onTap: () => goUserPage(context, widget.post.uid),
                    child: Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            "@${widget.post.username}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                  // Follow Button
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement follow action
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Follow"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            //Post Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.message,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),

            const SizedBox(height: 40),

            //Timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                formattedTimestamp,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),

            //Like & Comment Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [

                  GestureDetector(
                    onTap: () async {
                      await databaseProvider.toggleLike(widget.post.id);
                    },
                    child: Row(
                      children: [
                        Icon(
                          likedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                          color: likedByCurrentUser ? Colors.red : Theme.of(context).colorScheme.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          likeCount.toString(),
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {}, // Open comment input
                    child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 1),
                          child: GestureDetector(
                              onTap: _openNewCommentBox,
                              child: Icon(
                                Icons.comment_rounded,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              )
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          commentCount != 0 ?
                          commentCount.toString()
                              : '0',
                          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            //"Most Recent Replies" Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Most recent replies",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_drop_down, size: 24, color: Colors.grey),
                ],
              ),
            ),

            Divider(
              thickness: 1,
              color: Theme.of(context).colorScheme.primary,
            ),

            //Comments Section
            allComments.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No comments yet..."),
              ),
            )
                : ListView.builder(
              itemCount: allComments.length,
              physics: const NeverScrollableScrollPhysics(), // Prevent scrolling conflict
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final comment = allComments[index];
                return CommentTile(
                    comment: comment,
                    onUserTap: () => goUserPage(context, comment.uid)
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
