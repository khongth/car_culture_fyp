import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import '../auth/auth_cubit.dart';
import '../models/comment.dart';

class CommentTile extends StatelessWidget {

  final Comment comment;
  final void Function()? onUserTap;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onUserTap
  });

  void _showOptions(BuildContext context) {

    String? currentUserId = context.read<AuthCubit>().state.user?.uid;
    final bool isOwnComment = comment.uid == currentUserId;

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

                      await Provider.of<DatabaseProvider>(context, listen: false).deleteComment(comment.id, comment.postId);
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text("Report"),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Block User"),
                    onTap: () {
                      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Profile Picture
              GestureDetector(
                onTap: onUserTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onUserTap,
                          child: Row(
                            children: [
                              Text(
                                comment.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                ),
                              ),
                              const SizedBox(width: 5),

                              Text(
                                "@${comment.username}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 5),

                              //Timestamp
                              Text(
                                "· 5m",
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

                    Text(
                      comment.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              //More Options
              GestureDetector(
                onTap: () => _showOptions(context),
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
    );
  }
}
