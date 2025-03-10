import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String bio;

  UserProfile ({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
        uid: doc['uid'],
        email: doc['email'],
        username: doc['username'],
        bio: doc['bio']);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid' : uid,
      'email': email,
      'username': username,
      'bio': bio,
    };
  }
}