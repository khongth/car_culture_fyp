import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HomeCubit() : super(HomeInitial());

  // Fetch user posts
  Future<void> fetchPosts() async {
    try {
      emit(HomeLoading()); // Show loading state
      final snapshot = await _firestore.collection("User Posts")
          .orderBy("TimeStamp", descending: true)
          .get();
      List<Map<String, dynamic>> posts = snapshot.docs.map((doc) => {
        "message": doc["Message"],
        "user": doc["UserEmail"],
        "time": doc["TimeStamp"].toDate().toString(),
      }).toList();
      emit(HomeLoaded(posts: posts));
    } catch (e) {
      emit(HomeError(message: "Error fetching posts: $e"));
    }
  }

  // Post a new message
  Future<void> postMessage(String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && message.isNotEmpty) {
        await _firestore.collection("User Posts").add({
          "UserEmail": currentUser.email,
          "Message": message,
          "TimeStamp": Timestamp.now(),
        });
        emit(HomeMessagePosted());
        fetchPosts(); // Reload posts after posting
      }
    } catch (e) {
      emit(HomeError(message: "Error posting message: $e"));
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      emit(HomeInitial()); // Reset state first
      await Future.delayed(Duration(milliseconds: 100)); // Allow UI to update
      emit(HomeSignedOut()); // Now emit sign-out state
    } catch (e) {
      emit(HomeError(message: "Error signing out: $e"));
    }
  }


}
