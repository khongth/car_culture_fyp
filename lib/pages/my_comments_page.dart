import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../helper/navigatet_pages.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/database_provider.dart';

class MyCommentsPage extends StatefulWidget {
  const MyCommentsPage({Key? key}) : super(key: key);

  @override
  State<MyCommentsPage> createState() => _MyCommentsPageState();
}

class _MyCommentsPageState extends State<MyCommentsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<DatabaseProvider>(context, listen: false).loadUserComments();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Comments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<DatabaseProvider>(
        builder: (context, databaseProvider, child) {
          final comments = databaseProvider.userComments;

          if (comments.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t made any comments yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadComments,
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return CommentListItem(
                  comment: comment,
                  onPostTap: (postId) async {
                    final post = await Provider.of<DatabaseProvider>(
                        context,
                        listen: false)
                        .getPostById(comment.postId);

                    if (post != null) {
                      goPostPage(context, post);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CommentListItem extends StatelessWidget {
  final Comment comment;
  final Function(String postId) onPostTap;

  const CommentListItem({
    Key? key,
    required this.comment,
    required this.onPostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => onPostTap(comment.postId),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with username and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'On Post #${comment.postId.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    timeago.format(comment.timestamp.toDate()),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Comment message text
              Text(
                comment.message,
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // If the comment has an image, display it below the username
              if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    comment.imageUrl!,
                    height: 100, // Adjust size to match the image size in your example
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),

              // Display post image on the right, if available
              Consumer<DatabaseProvider>(
                builder: (context, databaseProvider, child) {
                  return FutureBuilder<Post?>(
                    future: databaseProvider.getPostById(comment.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }

                      if (snapshot.hasData) {
                        final post = snapshot.data!;
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Image.network(
                              post.imageUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      }

                      return const SizedBox();
                    },
                  );
                },
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to view post',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
