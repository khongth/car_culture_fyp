import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../auth/auth_cubit.dart';
import '../models/comment.dart';
import '../models/user.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final void Function()? onUserTap;

  const CommentTile({
    Key? key,
    required this.comment,
    required this.onUserTap,
  }) : super(key: key);

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  UserProfile? _user;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      final userProfile = await databaseProvider.userProfile(widget.comment.uid);

      if (mounted) {
        setState(() {
          _user = userProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOptions() {
    final String? currentUserId = context.read<AuthCubit>().state.user?.uid;
    final bool isOwnComment = widget.comment.uid == currentUserId;
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                if (isOwnComment)
                  ListTile(
                    leading: const Icon(IconlyBold.delete),
                    title: const Text("Delete"),
                    onTap: () async {
                      Navigator.pop(context);
                      await databaseProvider.deleteComment(
                          widget.comment.id,
                          widget.comment.postId
                      );
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text("Report"),
                    onTap: () {
                      Navigator.pop(context);
                      _reportCommentConfirmationBox();
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
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
    );
  }

  void _reportCommentConfirmationBox() {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Report Comment"),
          content: const Text("Are you sure you want to report this comment?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")
            ),
            TextButton(
                onPressed: () async {
                  await databaseProvider.reportUser(
                      widget.comment.id,
                      widget.comment.uid
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Comment reported!"))
                    );
                  }
                },
                child: const Text("Report")
            )
          ],
        )
    );
  }

  void _blockUserConfirmationBox() {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Block User"),
          content: const Text("Are you sure you want to block this user?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")
            ),
            TextButton(
                onPressed: () async {
                  await databaseProvider.blockUser(widget.comment.uid);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User Blocked!"))
                    );
                  }
                },
                child: const Text("Block")
            )
          ],
        )
    );
  }

  String _formatTimeAgo(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return timeago.format(dateTime, locale: 'short');
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTimeAgo = _formatTimeAgo(widget.comment.timestamp);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              GestureDetector(
                onTap: widget.onUserTap,
                child: _isLoading
                    ? const CircleAvatar(
                  radius: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : CircleAvatar(
                  radius: 20,
                  backgroundImage: _user?.profileImageUrl.isNotEmpty == true
                      ? NetworkImage(_user!.profileImageUrl)
                      : null,
                  child: _user?.profileImageUrl.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info row
                    GestureDetector(
                      onTap: widget.onUserTap,
                      child: Row(
                        children: [
                          Text(
                            widget.comment.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.inversePrimary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "@${widget.comment.username}",
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "· $formattedTimeAgo",
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comment Text
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.comment.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.inversePrimary,
                        ),
                      ),
                    ),

                    // Display Image if available
                    if (widget.comment.imageUrl != null && widget.comment.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.comment.imageUrl!,
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
                                child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // More Options
              GestureDetector(
                onTap: _showOptions,
                child: Icon(Icons.more_horiz, color: colorScheme.tertiary),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 1,
          color: colorScheme.primary,
        ),
      ],
    );
  }
}