import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../pages/chat_page.dart';
import '../services/database_provider.dart';

class InboxPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  const InboxPage({Key? key, this.onDrawerOpen}) : super(key: key);

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<DatabaseProvider>(context, listen: false).loadInbox();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context);
    final latestMessages = db.inboxLatestMessages;
    final userProfiles = db.inboxUserProfiles;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            if (widget.onDrawerOpen != null) {
              widget.onDrawerOpen!();
            }
          },
        ),
        title: const Text('Inbox'),
      ),
      body: latestMessages.isEmpty
          ? const Center(child: Text("No chats yet"))
          : ListView.builder(
        itemCount: latestMessages.length,
        itemBuilder: (context, index) {
          final chatRoomId = latestMessages.keys.elementAt(index);
          final message = latestMessages[chatRoomId]!;
          final user = userProfiles[chatRoomId];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl)
                  : null,
              child: user?.profileImageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(user?.username ?? 'Unknown'),
            subtitle: message.imageUrl != null
                ? const Text('[Image]')
                : Text(message.message),
            trailing: Text(
              DateFormat('hh:mm a').format(message.timestamp.toDate()),
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverEmail: user.email,
                      receiverId: user.uid,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
