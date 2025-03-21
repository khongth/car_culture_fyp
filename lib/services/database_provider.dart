import 'dart:io';
import 'package:car_culture_fyp/models/post.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:car_culture_fyp/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/comment.dart';
import '../models/event.dart';
import '../models/marketplace.dart';
import '../models/message.dart';

class DatabaseProvider extends ChangeNotifier {
  final _db = DatabaseService();

  //Get user profile when given UID
  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  Future<void> updateBio(String bio) => _db.updateUserBioInFirebase(bio);

  Future<void> updateProfilePicture(File imageFile) => _db.updateUserProfileImageInFirebase(imageFile);

  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];

  List<Post> get allPosts => _allPosts;
  List<Post> get followingPosts => _followingPosts;

  Future<void> postMessage(String message, {File? imageFile}) async {
    await _db.postMessageInFirebase(message, imageFile: imageFile);

    await loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    final allPosts = await _db.getAllPostsFromFirebase();
    final blockedByUserIds = await _db.getBlockedByFromFirebase();

    // Filter posts:
    // 1. Current user should not see posts from users who blocked them (BlockedBy list)
    // 2. Users the current user has blocked are still visible
    _allPosts = allPosts.where((post) => !blockedByUserIds.contains(post.uid)).toList();

    loadFollowingPosts();
    initializeLikeMap();

    for (var post in allPosts) {
      await loadComments(post.id);
    }

    notifyListeners();
  }

  Future<void> loadFollowingPosts() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    final followingUserIds = await _db.getFollowingUidsFromFirebase(currentUserId!);
    
    _followingPosts = _allPosts.where((post) => followingUserIds.contains(post.uid)).toList();

    notifyListeners();
  }

  Future<Post?> getPostById(String postId) async {
    try {
      // Fetch the post from the database
      Post? post = await _db.getPostById(postId);

      if (post != null) {
        notifyListeners(); // If needed
      }

      return post;
    } catch (e) {
      print("Error fetching post by ID: $e");
      return null;
    }
  }

  //Filter and return user post in User Profile
  List<Post> filterUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  Future<void> deletePost(String postId) async {
    await _db.deletePostFromFirebase(postId);

    await loadAllPosts();
    
  }

  Map<String, int> _likeCounts = {};

  List<String> _likedPosts = [];

  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);

  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  void initializeLikeMap() {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    _likedPosts.clear();

    for (var post in _allPosts) {
      _likeCounts[post.id] = post.likeCount;

      if (post.likedBy.contains(currentUserId)) {
        _likedPosts.add(post.id);
      }
    }
  }

  Future<void> toggleLike(String postId) async {
    //Update local UI first
    final likedPostsOriginal = _likedPosts;
    final likeCountsOriginal = _likeCounts;

    if (_likedPosts.contains(postId)) {
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }

    notifyListeners();

    //attempt like in database
    try {
      await _db.toggleLikeInFirebase(postId);
    } catch (e) {
      _likedPosts = likedPostsOriginal;
      _likeCounts = likeCountsOriginal;

      notifyListeners();
    }
  }

  final Map<String, List<Comment>> _comments = {};

  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  Future<void> loadComments(String postId) async {
    final allComments = await _db.getCommentsFromFirebase(postId);

    _comments[postId] = allComments;

    notifyListeners();
  }

  Future<void> addComment(String postId, message, {File? imageFile}) async {
    await _db.addCommentInFirebase(postId, message, imageFile: imageFile);
    await loadComments(postId);
  }

  Future<void> deleteComment(String commentId, postId) async {
    await _db.deleteCommentInFirebase(commentId);
    await loadComments(postId);
  }

  List<Comment> _userComments = [];
  List<Comment> get userComments => _userComments;

  Future<void> loadUserComments() async {
    _userComments = await _db.getUserCommentsFromFirebase();
    notifyListeners();
  }

  List<UserProfile> _blockedUsers = [];
  List<UserProfile> _blockedBy = [];

  List<UserProfile> get blockedUsers => _blockedUsers;
  List<UserProfile> get blockedBy => _blockedBy;

  Future<void> loadBlockedUsers() async {
    final blockedUserIds = await _db.getBlockedUidsFromFirebase();
    
    final blockedUsersData = await Future.wait(blockedUserIds.map((id) => _db.getUserFromFirebase(id)));

    _blockedUsers = blockedUsersData.whereType<UserProfile>().toList();

    notifyListeners();
  }

  Future<void> loadBlockedBy() async {
    final blockedBy = await _db.getBlockedByFromFirebase();

    final blockedByData = await Future.wait(blockedBy.map((id) => _db.getUserFromFirebase(id)));

    _blockedBy = blockedByData.whereType<UserProfile>().toList();

    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    await _db.blockUserInFirebase(userId);

    await loadBlockedUsers();
    await loadAllPosts();
    notifyListeners();
  }

  Future<void> unblockUser(String blockedUserId) async {
    await _db.unblockUserInFirebase(blockedUserId);

    await loadBlockedUsers();
    await loadAllPosts();
    notifyListeners();
  }

  Future<void> reportUser(String postId, userId) async {
    await _db.reportUserInFirebase(postId, userId);
  }

  final Map<String, List<String>> _followers = {};
  final Map<String, List<String>> _following = {};
  final Map<String, int> _followerCount = {};
  final Map<String, int> _followingCount = {};

  int getFollowerCount(String uid) => _followerCount[uid] ?? 0;
  int getFollowingCount(String uid) => _followingCount[uid] ?? 0;

  Future<void> loadUserFollowers(String uid) async {
    final listOfFollowersUids = await _db.getFollowersUidsFromFirebase(uid);

    _followers[uid] = listOfFollowersUids;
    _followerCount[uid] = listOfFollowersUids.length;

    notifyListeners();
  }

  Future<void> loadUserFollowing(String uid) async {
    final listOfFollowingUids = await _db.getFollowingUidsFromFirebase(uid);

    _following[uid] = listOfFollowingUids;
    _followingCount[uid] = listOfFollowingUids.length;

    notifyListeners();
  }

  Future<void> followUser(String targetUserId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(targetUserId, () => []);

    if (!_followers[targetUserId]!.contains(currentUserId)) {
      _followers[targetUserId]?.add(currentUserId);
      _followerCount[targetUserId] = (_followerCount[targetUserId] ?? 0) + 1;

      _following[currentUserId]?.add(targetUserId);
      _followerCount[currentUserId] = (_followingCount[currentUserId] ?? 0) + 1;
    }

    notifyListeners();

    try {

      await _db.followUserInFirebase(targetUserId);
      await loadUserFollowers(currentUserId);
      await loadUserFollowing(currentUserId);

    } catch (e) {

      _followers[targetUserId]?.remove(currentUserId);
      _followerCount[targetUserId] = (_followerCount[targetUserId]??0)-1;

      _following[currentUserId]?.remove(targetUserId);
      _followerCount[currentUserId] = (_followingCount[currentUserId] ?? 0) - 1;

      notifyListeners();
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(targetUserId, () => []);

    if (!_followers[targetUserId]!.contains(currentUserId)) {
      _followers[targetUserId]?.remove(currentUserId);
      _followerCount[targetUserId] = (_followerCount[targetUserId] ?? 1) - 1;

      _following[currentUserId]?.remove(targetUserId);
      _followerCount[currentUserId] = (_followingCount[currentUserId] ?? 1) - 1;
    }

    notifyListeners();

    try {

      await _db.unfollowUserInFirebase(targetUserId);
      await loadUserFollowers(currentUserId);
      await loadUserFollowing(currentUserId);

    } catch (e) {

      _followers[targetUserId]?.add(currentUserId);
      _followerCount[targetUserId] = (_followerCount[targetUserId]??0)+1;

      _following[currentUserId]?.add(targetUserId);
      _followerCount[currentUserId] = (_followingCount[currentUserId] ?? 0) + 1;

      notifyListeners();
    }
  }

  bool isFollowing(String uid) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return _followers[uid]?.contains(currentUserId) ?? false;
  }

  final Map<String, List<UserProfile>> _followersProfile = {};
  final Map<String, List<UserProfile>> _followingProfile = {};

  List<UserProfile> getListOfFollowersProfile(String uid)  => _followersProfile[uid] ?? [];
  List<UserProfile> getListOfFollowingProfile(String uid)  => _followingProfile[uid] ?? [];

  Future<void> loadUserFollowersProfiles(String uid) async {
    try {

      final followerIds = await _db.getFollowersUidsFromFirebase(uid);

      List<UserProfile> followerProfiles = [];

      for (String followerId in followerIds) {
        UserProfile? followerProfile = await _db.getUserFromFirebase(followerId);

        if (followerProfile != null) {
          followerProfiles.add(followerProfile);
        }
      }

      _followersProfile[uid] = followerProfiles;
      notifyListeners();

    } catch (e) {
      print(e);
    }
  }

  Future<void> loadUserFollowingProfiles(String uid) async {
    try {

      final followingIds = await _db.getFollowingUidsFromFirebase(uid);

      List<UserProfile> followingProfiles = [];

      for (String followingId in followingIds) {
        UserProfile? followingProfile = await _db.getUserFromFirebase(followingId);

        if (followingProfile != null) {
          followingProfiles.add(followingProfile);
        }
      }

      _followingProfile[uid] = followingProfiles;
      notifyListeners();

    } catch (e) {
      print(e);
    }
  }

  List<UserProfile> _searchResults = [];


  List<UserProfile> get searchResult => _searchResults;

  Future<void> searchUsers(String searchTerm) async {
    try {
      final results = await _db.searchUsersInFirebase(searchTerm);

      _searchResults = results;

      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> clearSearchResults() async {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> searchMarketplace(String searchTerm) async {
    try {
      final marketplaceResults = await _db.searchMarketplaceItems(searchTerm);

      _marketplaceSearchResult = marketplaceResults;

      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  List<MarketplacePost> _marketplacePosts = [];
  List<MarketplacePost> _yourMarketplacePosts = [];
  List<MarketplacePost> _marketplaceSearchResult = [];
  List<MarketplacePost> get marketplacePosts => _marketplacePosts;
  List<MarketplacePost> get youMarketplacePosts => _yourMarketplacePosts;
  List<MarketplacePost> get marketplaceSearchResult => _marketplaceSearchResult;

  Future<void> postMarketplaceItem(String title, String description, double price, {List<File>? imageFiles}) async {
    await _db.postMarketplaceItem(title, description, price, imageFiles: imageFiles);
    await loadMarketplacePosts();
  }

  Future<void> loadMarketplacePosts() async {
    _marketplacePosts = await _db.getMarketplacePosts();
    notifyListeners();
  }

  Future<void> loadYourMarketplaceListing() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final userMarketplacePosts = await _db.getUserMarketplacePosts(currentUserId);

    _yourMarketplacePosts = userMarketplacePosts;

    notifyListeners();
  }
  List<CarEvent> _carEvents = [];
  bool _isLoadingEvents = false;

  List<CarEvent> get carEvents => _carEvents;
  bool get isLoadingEvents => _isLoadingEvents;

  Future<void> loadCarEvents() async {
    _isLoadingEvents = true;
    notifyListeners();

    final events = await _db.getCarEventsFromFirebase();

    _carEvents = events;
    _isLoadingEvents = false;

    notifyListeners();
  }

  Future<void> addCarEvent(String name, String location, String description, DateTime date, LatLng position) async {
    await _db.addCarEventInFirebase(name: name, location: location, description: description, date: date, position: position);
    await loadCarEvents();
  }

  Map<String, Message> _inboxLatestMessages = {};
  Map<String, UserProfile> _inboxUserProfiles = {};

  Map<String, Message> get inboxLatestMessages => _inboxLatestMessages;
  Map<String, UserProfile> get inboxUserProfiles => _inboxUserProfiles;

  Future<void> loadInbox() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final chatRoomIds = await _db.getUserChatRoomIds();

    Map<String, Message> latestMessagesMap = {};
    Map<String, UserProfile> userProfilesMap = {};

    for (String roomId in chatRoomIds) {
      final message = await _db.getLatestMessageFromChatRoom(roomId);
      if (message != null) {
        latestMessagesMap[roomId] = message;

        String otherUserId = message.senderId == currentUserId
            ? message.receiverId
            : message.senderId;

        final otherUserProfile = await _db.getUserFromFirebase(otherUserId);

        if (otherUserProfile != null) {
          userProfilesMap[roomId] = otherUserProfile;
        }
      }
    }

    _inboxLatestMessages = latestMessagesMap;
    _inboxUserProfiles = userProfilesMap;

    notifyListeners();
  }
}