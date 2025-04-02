import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helper/navigatet_pages.dart';
import '../models/report.dart';
import '../services/database_provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoading = true;
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);

  @override
  void initState() {
    super.initState();
    _loadReports();
    loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    await databaseProvider.loadAllPosts();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    // Load reports from the database
    await Provider.of<DatabaseProvider>(context, listen: false).loadReports();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("All Reports"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Log out logic
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<DatabaseProvider>( // Watch reports state
        builder: (context, databaseProvider, child) {
          final reports = databaseProvider.reports;

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'No reports available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return ReportListItem(
                  report: report,
                  onTap: () {},
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class ReportListItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportListItem({Key? key, required this.report, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        Provider.of<DatabaseProvider>(context, listen: false).getUserEmail(report.reportedBy),
        Provider.of<DatabaseProvider>(context, listen: false).getPostOrCommentMessage(report.messageId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading report data'));
        }

        final userEmail = snapshot.data![0] as String;
        final message = snapshot.data![1] as String;

        if (message == "No message available" || message == null) {
          return SizedBox.shrink(); // Hide this tile
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () async {
              // Check if the messageId corresponds to a post or a comment
              final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
              final isPost = await databaseProvider.isPost(report.messageId);

              if (isPost) {
                // Navigate to post page
                final post = await databaseProvider.getPostById(report.messageId);
                if (post != null) {
                  goPostPage(context, post);
                }
              } else {
                // For now, we can navigate to the post that contains the comment
                final comment = await databaseProvider.getCommentById(report.messageId);
                if (comment != null) {
                  // Get the post that this comment belongs to
                  final post = await databaseProvider.getPostById(comment.postId);
                  if (post != null) {
                    goPostPage(context, post);
                    // The post page will show all comments including the reported one
                  }
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported by: $userEmail',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        report.timestamp.toDate().toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Report message text
                  Text(
                    '"$message"',
                    style: const TextStyle(fontSize: 16),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tap to view details',
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
      },
    );
  }
}

