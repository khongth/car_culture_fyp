import 'dart:io';
import 'package:car_culture_fyp/models/post.dart';
import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../auth/auth_cubit.dart';
import '../models/user.dart';
import 'comment_input.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;

  const PostTile({
    super.key,
    required this.post,
    required this.onUserTap,
    required this.onPostTap,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {

  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  final _commentController = TextEditingController();
  File? _selectedImage;
  UserProfile? user;

  @override
  void initState() {
    super.initState();

    loadUser();
    _loadComments();
  }

  Future<void> loadUser() async {
    user = await databaseProvider.userProfile(widget.post.uid);
  }

  void _toggleLikePost() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch(e) {
      print(e);
    }
  }

  void _openNewCommentBox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to adjust height dynamically
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) {
        return SingleChildScrollView( // Make the content scrollable
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height, // Ensure minimum height is the screen height
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onImageSelected: (image) {
                setState(() {
                  _selectedImage = image;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImage == null) return;

    try {
      await databaseProvider.addComment(widget.post.id, _commentController.text.trim(), imageFile: _selectedImage);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadComments() async {
    await databaseProvider.loadComments(widget.post.id);
  }

  void _showOptions() {

    String? currentUserId = context.read<AuthCubit>().state.user?.uid;
    final bool isOwnPost = widget.post.uid == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [

            if (isOwnPost)
              ListTile(
                leading: const Icon(IconlyBold.delete),
                title: const Text("Delete"),
                onTap: () async {
                  Navigator.pop(context);

                  await databaseProvider.deletePost(widget.post.id );
                },
              )
            else ...[
              ListTile(
              leading: const Icon(Icons.flag),
              title: const Text("Report"),
              onTap: () {
                Navigator.pop(context);

                _reportPostConfirmationBox();
              },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text("Block User"),
                onTap: () {
                  Navigator.pop(context);

                  _blockUserConfirmationBox();
                },
              ),
            ],
          
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }
  
  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Message"),
        content: const Text("Are you sure you want to report this message?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Cancel")
          ),
          TextButton(
              onPressed: () async{
                await databaseProvider.reportUser(widget.post.id, widget.post.uid);

                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message reported!")));
              },
              child: Text("Report")
          )
        ],
      )
    );
  }

  void _blockUserConfirmationBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Block User"),
          content: const Text("Are you sure you want to block this user?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel")
            ),
            TextButton(
                onPressed: () async{
                  await databaseProvider.blockUser(widget.post.uid);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User Blocked!")));
                },
                child: Text("Block")
            )
          ],
        )
    );
  }

  String shortTimeAgo(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return timeago.format(dateTime, locale: 'short');
  }

  @override
  Widget build(BuildContext context) {

    String formattedTimeAgo = shortTimeAgo(widget.post.timestamp);

    bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(widget.post.id);

    int likeCount = listeningProvider.getLikeCount(widget.post.id);
    int commentCount = listeningProvider.getComments(widget.post.id).length;

    return GestureDetector(
      onTap: widget.onPostTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Profile Picture
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: CircleAvatar(
                    backgroundImage: user?.profileImageUrl.isNotEmpty == true
                        ? NetworkImage(user!.profileImageUrl)
                        : null,
                    child: user?.profileImageUrl.isNotEmpty == true
                        ? null
                        : CircularProgressIndicator(),
                  )
                ),
                const SizedBox(width: 10),
      
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onUserTap,
                            child: Row(
                              children: [
                                Text(
                                  widget.post.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                ),
                                const SizedBox(width: 5),
      
                                Text(
                                  "@${widget.post.username}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 5),
      
                                //Timestamp
                                Text(
                                  "· $formattedTimeAgo",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      
                      const SizedBox(height: 5),
      
                      //Post Content
                      Text(
                        widget.post.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),

                      Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Row(
                              children: [
                                GestureDetector(
                                    onTap: _toggleLikePost,
                                    child: likedByCurrentUser ?
                                    Icon(Icons.favorite, color: Colors.red, size: 20,)
                                        : Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.tertiary, size: 20)
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  likeCount != 0 ?
                                  likeCount.toString()
                                      : '0',
                                  style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                                ),
                              ],
                            ),
                          ),

                          //Comment
                          Row(
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
                        ],
                      ),
                    ],
                  ),
                ),
      
                //More Options (3-dots menu)
                GestureDetector(
                  onTap: _showOptions,
                  child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.tertiary),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
