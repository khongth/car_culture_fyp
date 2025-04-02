import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String bio;
  final String profileImageUrl;
  final Timestamp dateCreated;

  UserProfile ({
    required this.uid,
    required this.email,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    required this.dateCreated,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'],
      email: doc['email'],
      username: doc['username'],
      bio: doc['bio'],
      profileImageUrl: doc['profileImageUrl'],
      dateCreated: doc['dateCreated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid' : uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'dateCreated': dateCreated,
    };
  }
}