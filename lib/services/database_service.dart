
import 'dart:io';
import 'package:car_culture_fyp/models/comment.dart';
import 'package:car_culture_fyp/models/message.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/event.dart';
import '../models/marketplace.dart';
import '../models/post.dart';

//Handles data to and from firebase
class DatabaseService {

  final _store = FirebaseStorage.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  //User Profile
  //Save User Info
  Future<void> saveUserInfoInFirebase({required String email}) async {
    //Get current uid
    String uid = _auth.currentUser!.uid;

    String username = email.split('@')[0];
    String defaultProfileImageUrl = await _getDefaultProfileImageUrl();

    UserProfile user = UserProfile(
      uid: uid,
      email: email,
      username: username,
      bio: '',
      profileImageUrl: defaultProfileImageUrl,
    );

    final userMap = user.toMap();

    await _db.collection("Users").doc(uid).set(userMap);
  }

  Future<String> _getDefaultProfileImageUrl() async {
    try {
      final ref = _store.ref().child('profile_images/defaultprofilepicture.png');
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;  // Returning the download URL of the default image
    } catch (e) {
      print("Error fetching default profile image: $e");
      return '';  // Returning empty string in case of error
    }
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

  Future<void> updateUserProfileImageInFirebase(File imageFile) async {
    String uid = _auth.currentUser!.uid;

    try {
      String? profileImageUrl = await _uploadProfileImageToStorage(imageFile, uid);

      if (profileImageUrl != null) {
        await _db.collection("Users").doc(uid).update({'profileImageUrl': profileImageUrl});
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String?> _uploadProfileImageToStorage(File imageFile, String uid) async {
    try {
      String filePath = 'profile_images/$uid.jpg';
      final ref = _store.ref().child(filePath);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }

  Future<void> postMessageInFirebase(String message, {File? imageFile}) async {
    try {

      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      DocumentReference postRef = _db.collection("Posts").doc();
      String postId = postRef.id;
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await _uploadImageToStorage(imageFile, postId);
      }

      Post newPost = Post(
        id: '',
        uid: uid,
        name: user!.email,
        username: user.username,
        message: message,
        timestamp: FieldValue.serverTimestamp(),
        likeCount: 0,
        likedBy: [],
        imageUrl: imageUrl,
      );

      Map<String, dynamic> newPostMap = newPost.toMap();

      await postRef.set(newPostMap);
    } catch (e) {
      print(e);
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile, String postId) async {
    try {
      String filePath = 'post_images/$postId.jpg';

      final ref = _store.ref().child(filePath);
      await ref.putFile(imageFile);

      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
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

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Post(
          id: doc.id,
          uid: data['uid'] ?? '',
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          message: data['message'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
          likeCount: data['likes'] ?? 0,
          likedBy: List<String>.from(data['likedBy'] ?? []),
          imageUrl: data['imageUrl'],
        );
      }).toList();
    } catch (e) {
      print("Error retrieving posts: $e");
      return [];
    }
  }

  Future<void> addCommentInFirebase(String postId, message, {File? imageFile}) async {
    try {
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserFromFirebase(uid);

      DocumentReference commentRef = _db.collection("Comments").doc();
      String commentId = commentRef.id;
      String? imageUrl;

      if (imageFile != null) {
        print('Uploading image for comment $commentId...');
        imageUrl = await _uploadCommentImageToStorage(imageFile, commentId);
        print('Image URL: $imageUrl');
      }

      Comment newComment = Comment(
        id: '', // auto-generated
        postId: postId,
        uid: uid,
        name: user!.email,
        username: user.username,
        message: message,
        timestamp: FieldValue.serverTimestamp(),
        imageUrl: imageUrl, // add imageUrl to the comment data
      );

      Map<String, dynamic> newCommentMap = newComment.toMap();

      await commentRef.set(newCommentMap);

      print('Comment added successfully');
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Future<String?> _uploadCommentImageToStorage(File imageFile, String commentId) async {
    try {
      String filePath = 'comment_images/$commentId.jpg';

      final ref = _store.ref().child(filePath);
      await ref.putFile(imageFile);

      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading comment image: $e");
      return null;
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

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Comment(
          id: doc.id,
          postId: data['postId'] ?? '',
          uid: data['uid'] ?? '',
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          message: data['message'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          imageUrl: data['imageUrl'],
        );
      }).toList();
    } catch (e) {
      print("Error retrieving comments: $e");
      return [];
    }
  }

  Future<List<Comment>> getUserCommentsFromFirebase() async {
    try {
      String uid = _auth.currentUser!.uid;

      QuerySnapshot snapshot = await _db
          .collection("Comments")
          .where("uid", isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Comment(
          id: doc.id,
          postId: data['postId'] ?? '',
          uid: data['uid'] ?? '',
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          message: data['message'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          imageUrl: data['imageUrl'],
        );
      }).toList();
    } catch (e) {
      print("Error retrieving user comments: $e");
      return [];
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _db.collection('Posts').doc(postId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        return Post(
          id: doc.id,
          uid: data['uid'] ?? '',
          username: data['username'] ?? '',
          name: data['name'] ?? '',
          message: data['message'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
          likeCount: (data['likes'] as int?) ?? 0, // Ensure likeCount is an integer
          likedBy: List<String>.from(data['likedBy'] ?? []),
          imageUrl: data['imageUrl'],
        );
      }
      return null;
    } catch (e) {
      print("Error retrieving post by ID: $e");
      return null;
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

    //Remove the blocked user from the current user's followers and following lists
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(userId)
        .delete();

    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Followers")
        .doc(userId)
        .delete();

    await _db
        .collection("Users")
        .doc(userId)
        .collection("Following")
        .doc(currentUserId)
        ..delete();

    await _db
        .collection("Users")
        .doc(userId)
        .collection("Followers")
        .doc(currentUserId)
        ..delete();

    // Add the user to the blocked list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(userId)
        .set({});

    await _db
        .collection("Users")
        .doc(userId)
        .collection("BlockedBy")
        .doc(currentUserId)
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

    await _db
        .collection("Users")
        .doc(blockedUserId)
        .collection("BlockedBy")
        .doc(currentUserId)
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

  Future<List<String>> getBlockedByFromFirebase() async {
    final currentUserId = _auth.currentUser!.uid;

    final snapshot = await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedBy")
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

  Future<List<MarketplacePost>> searchMarketplaceItems(String searchTerm) async {
    try {
      String lowerSearchTerm = searchTerm.toLowerCase();

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection("Marketplace").get();

      List<MarketplacePost> results = [];

      for (var doc in querySnapshot.docs) {
        MarketplacePost post = MarketplacePost.fromDocument(doc);

        String lowerTitle = post.title.toLowerCase();
        String lowerDescription = post.description.toLowerCase();

        if (lowerTitle.contains(lowerSearchTerm) || lowerDescription.contains(lowerSearchTerm)) {
          results.add(post);
        }
      }

      return results;
    } catch (e) {
      print("Error searching marketplace items: $e");
      return [];
    }
  }

  Future<void> sendMessage(String receiverId, message, {File? imageFile}) async {

    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await uploadImageToStorage(imageFile);
    }

    Message newMessage = Message(
        senderId: currentUserID,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp,
        imageUrl: imageUrl,
    );

    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _db
        .collection("Chat")
        .doc(chatRoomID)
        .collection("Messages")
        .add(newMessage.toMap());
  }

  Future<String?> uploadImageToStorage(File imageFile) async {
    try {
      String filePath = 'chat_images/${DateTime.now().toIso8601String()}.jpg';
      final ref = _store.ref().child(filePath);
      await ref.putFile(imageFile);

      return await ref.getDownloadURL(); // Return the image URL
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _db
        .collection("Chat")
        .doc(chatRoomID)
        .collection("Messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<void> postMarketplaceItem(String title, String description, double price, {List<File>? imageFiles}) async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentReference postRef = _db.collection("Marketplace").doc();
      String postId = postRef.id;
      List<String>? imageUrls;

      if (imageFiles != null && imageFiles.isNotEmpty) {
        imageUrls = await _uploadMarketplaceImagesToStorage(imageFiles, postId);
      }

      MarketplacePost newPost = MarketplacePost(
        id: postId,
        uid: uid,
        title: title,
        description: description,
        price: price,
        timestamp: FieldValue.serverTimestamp(),
        imageUrls: imageUrls,
      );

      await postRef.set(newPost.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<List<String>> _uploadMarketplaceImagesToStorage(List<File> imageFiles, String postId) async {
    List<String> imageUrls = [];
    try {
      for (int i = 0; i < imageFiles.length; i++) {
        String filePath = 'marketplace_images/$postId$i.jpg';
        final ref = _store.ref().child(filePath);
        await ref.putFile(imageFiles[i]);
        String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
      return imageUrls;
    } catch (e) {
      print("Error uploading images: $e");
      return [];
    }
  }

  Future<List<MarketplacePost>> getMarketplacePosts() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Marketplace")
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => MarketplacePost.fromDocument(doc)).toList();
    } catch (e) {
      print("Error retrieving marketplace posts: $e");
      return [];
    }
  }

  Future<List<MarketplacePost>> getUserMarketplacePosts(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection("Marketplace")
          .where("uid", isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) => MarketplacePost.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching user marketplace listings: $e");
      return [];
    }
  }

  Future<List<CarEvent>> getCarEventsFromFirebase() async {
    try {
      final snapshot = await _db.collection('carEvents').orderBy('date', descending: false).get();
      return snapshot.docs.map((doc) => CarEvent.fromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<void> addCarEventInFirebase({
    required String name,
    required String location,
    required String description,
    required DateTime date,
    required LatLng position,
  }) async {
    try {
      // Generate a new document reference for the event
      DocumentReference eventRef = _db.collection("carEvents").doc();
      String eventId = eventRef.id;

      CarEvent newEvent = CarEvent(
        id: eventId, // Assign the generated ID
        name: name,
        location: location,
        description: description,
        date: date,
        position: position,
      );

      Map<String, dynamic> eventMap = newEvent.toMap();

      await eventRef.set(eventMap);
    } catch (e) {
      print("Error adding event: $e");
    }
  }
}

