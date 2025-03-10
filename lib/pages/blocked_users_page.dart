import 'package:car_culture_fyp/services/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {

  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();

    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    await databaseProvider.loadBlockedUsers();
  }

  void _showUnblockConfirmationBox(String userId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Unblock User"),
          content: const Text("Are you sure you want to unblock this user?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel")
            ),
            TextButton(
                onPressed: () async{
                  await databaseProvider.unblockUser(userId);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User unblocked!")));
                },
                child: Text("Unblock")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final blockedUsers = listeningProvider.blockedUsers;

    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
        centerTitle: true,
      ),

      body: blockedUsers.isEmpty ?
          Center(child: Text("No blocked users")) :
          ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];

                return ListTile(
                  title: Text(user.email),
                  subtitle: Text("@" + user.username),
                  trailing: IconButton(
                    onPressed: () => _showUnblockConfirmationBox(user.uid),
                    icon: Icon(Icons.block),
                  ),
                );
              }
          )
    );
  }
}
