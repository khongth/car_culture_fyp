import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profileImageUrl;

  UserProfile ({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'],
      email: doc['email'],
      username: doc['username'],
      bio: doc['bio'],
      profileImageUrl: doc['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid' : uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
    };
  }
}