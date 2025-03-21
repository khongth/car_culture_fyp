import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:car_culture_fyp/models/user.dart';
import '../components/user_list_tile.dart';
import '../helper/navigatet_pages.dart'; // Import the helper functions for navigation

class DiscoverFriendsPage extends StatelessWidget {
  const DiscoverFriendsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Friends"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .limit(20) // Limit to the most recent 20 users
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No recent users found."));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userProfile = UserProfile.fromDocument(user);

              return UserListTile(
                user: userProfile,
                uid: user.id,
                onUserTap: (uid) {
                  // Use goUserPage to navigate to the user profile page
                  goUserPage(context, uid);
                },
              );
            },
          );
        },
      ),
    );
  }
}
