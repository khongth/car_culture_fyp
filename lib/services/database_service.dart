
import 'package:car_culture_fyp/models/comment.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';


//Handles data to and from firebase
class DatabaseService {

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;


  //User Profile
  //Save User Info
  Future<void> saveUserInfoInFirebase({required String email}) async {
    //Get current uid
    String uid = _auth.currentUser!.uid;

    String username = email.split('@')[0];

    UserProfile user = UserProfile(
      uid: uid,
      email: email,
      username: username,
      bio: '',
    );

    final userMap = user.toMap();

    await _db.collection("Users").doc(uid).set(userMap);
  }

  //Get user info
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();

      //Convert to user profile
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> updateUserBioInFirebase(String bio) async {
    String uid = _auth.currentUser!.uid;

    try {
      await _db.collection("Users").doc(uid).update({'bio': bio});
    } catch (e) {
      print(e);
    }
  }

  Future<void> postMessageInFirebase(String message) async {
    try {

      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      Post newPost = Post(
          id: '',
          uid: uid,
          name: user!.email,
          username: user!.username,
          message: message,
          timestamp: FieldValue.serverTimestamp(),
          likeCount: 0,
          likedBy: [],
      );

      Map<String, dynamic> newPostMap = newPost.toMap();

      await _db.collection("Posts").add(newPostMap);
    } catch (e) {
      print(e);
    }
  }

  Future<void> deletePostFromFirebase(String postId) async {
    try {
      await _db.collection("Posts").doc(postId).delete();
    } catch(e) {
      print(e);
    }
  }

  Future<void> toggleLikeInFirebase(String postId) async {
    try{
      String uid = _auth.currentUser!.uid;

      DocumentReference postDoc = _db.collection("Posts").doc(postId);

      await _db.runTransaction(
        (transaction) async {

          DocumentSnapshot postSnapshot = await transaction.get(postDoc);

          List<String> likedBy = List<String>.from(postSnapshot['likedBy'] ?? []);

          int currentLikeCount = postSnapshot['likes'];

          if (!likedBy.contains(uid)) {
            likedBy.add(uid);
            currentLikeCount++;
          } else{
            likedBy.remove(uid);
            currentLikeCount--;
          }

          transaction.update(postDoc, {
            'likes': currentLikeCount,
            'likedBy': likedBy,
          });
        },
      );
    } catch(e) {
      print(e);
    }
  }

  Future<List<Post>> getAllPostsFromFirebase() async {
    try {

      QuerySnapshot snapshot = await _db
          .collection("Posts")
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();

    } catch (e) {
      return [];
    }
  }

  Future<void> addCommentInFirebase(String postId, message) async {
    try {
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      Comment newComment = Comment(
        id: '', //auto generated
        postId: postId,
        uid: uid,
        name: user!.email,
        username: user.username,
        message: message,
        timestamp: FieldValue.serverTimestamp(),
      );

      Map<String, dynamic> newCommentMap = newComment.toMap();
      
      await _db.collection("Comments").add(newCommentMap);

    } catch(e) {
      print(e);
    }
  }

  Future<void> deleteCommentInFirebase(String commentId) async {
    try {
      await _db.collection("Comments").doc(commentId).delete();
    } catch(e) {
      print(e);
    }
  }

  Future<List<Comment>> getCommentsFromFirebase(String postId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Comments")
          .where("postId", isEqualTo: postId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    } catch(e) {
      print(e);
      return [];
    }
  }

  Future<void> reportUserInFirebase(String postId, userId) async {
    final currentUserId = _auth.currentUser!.uid;

    final report = {
      'reportedBy': currentUserId,
      'messageId': postId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp()
    };

    await _db.collection("Reports").add(report);
  }

  Future<void> blockUserInFirebase(String userId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(userId)
        .set({});
  }

  Future<void> unblockUserInFirebase(String blockedUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(blockedUserId)
        .delete();
  }

  Future<List<String>> getBlockedUidsFromFirebase() async {
    final currentUserId = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .get();
    
    return snapshot.docs.map((doc) => doc.id).toList();
  }
  
  Future<void> deleteUserInfoFromFirebase(String uid) async {
    WriteBatch batch = _db.batch();
    
    DocumentReference userDoc = _db.collection("Users").doc(uid);
    batch.delete(userDoc);
    
    QuerySnapshot userPosts =
        await _db.collection("Posts").where('uid', isEqualTo: uid).get();

    for (var post in userPosts.docs) {
      batch.delete(post.reference);
    }

    QuerySnapshot userComments =
    await _db.collection("Comments").where('uid', isEqualTo: uid).get();

    for (var comment in userComments.docs) {
      batch.delete(comment.reference);
    }

    QuerySnapshot allPosts = await _db.collection("Posts").get();
    for (QueryDocumentSnapshot post in allPosts.docs) {
      Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
      var likedBy = postData['likedBy'] as List<dynamic>? ?? [];

      if (likedBy.contains(uid)) {
        batch.update(post.reference, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': FieldValue.increment(-1),
        });
      }
    }

    await batch.commit();
  }

  Future<void> followUserInFirebase(String uid) async {
    //Get current logged in user
    final currentUserId = _auth.currentUser!.uid;

    //Add target user to current user's following
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .set({});

    //Add current user to target user's followers
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .set({});
  }

  Future<void> unfollowUserInFirebase(String uid) async {
    //Get current logged in user
    final currentUserId = _auth.currentUser!.uid;

    //Remove target user from current user's following
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .delete();

    //Remove current user from target user's followers
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .delete();
  }

  Future<List<String>> getFollowersUidsFromFirebase(String uid) async {
    final snapshot =
        await _db.collection("Users").doc(uid).collection("Followers").get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> getFollowingUidsFromFirebase(String uid) async {
    final snapshot =
    await _db.collection("Users").doc(uid).collection("Following").get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }
  
  Future<List<UserProfile>> searchUsersInFirebase(String searchTerm) async {
    try {
      
      QuerySnapshot snapshot = await _db
          .collection("Users")
          .where('username', isGreaterThanOrEqualTo: searchTerm)
          .where('username', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromDocument(doc)).toList();

    } catch (e) {
      return [];
    }
  }
}