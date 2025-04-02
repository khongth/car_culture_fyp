import 'package:bloc/bloc.dart';
import 'package:car_culture_fyp/models/user.dart';
import 'package:car_culture_fyp/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../themes/theme_provider.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {

  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ThemeProvider themeProvider;

  static const String adminUid = 'u8VmTy8ar2hMRtNfZUZsqfI1Bx03';

  AuthCubit(this.themeProvider) : super(AuthState(user: FirebaseAuth.instance.currentUser)) {
    fetchUser();
  }

  void fetchUser() async {
    User? user = _firebaseAuth.currentUser;

    if (user != null) {
      await user.reload();
      user = _firebaseAuth.currentUser;

      bool isAdmin = user?.uid == adminUid;

      UserProfile? userProfile = await _db.getUserFromFirebase(user!.uid);
      String? username = userProfile?.username;

      emit(AuthState(user: user, username: username, isAdmin: isAdmin));
    }
  }

  // Login Method
  Future<void> login(String email, String password) async {
    emit(AuthState(isLoading: true)); // Show loading state

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = _firebaseAuth.currentUser;

      if (user != null) {
        await user.reload();
        fetchUser();
        emit(AuthState(successMessage: "Login successful", user: _firebaseAuth.currentUser));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthState(errorMessage: e.message)); // Emit error if login fails

    }
  }

  // SignUp Method
  Future<void> signUp(String email, String password) async {
    emit(AuthState(isLoading: true)); // Show loading state

    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.saveUserInfoInFirebase(email: email);

      fetchUser();
      emit(AuthState(successMessage: "Signup successful", user: _firebaseAuth.currentUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(errorMessage: e.message)); // Emit error if signup fails
    }
  }

  // Recover Password Method
  Future<void> recoverPassword(String email) async {
    emit(AuthState(isLoading: true)); // Show loading state

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      emit(AuthState(successMessage: "Password recovery email sent")); // Emit success state
    } catch (e) {
      emit(AuthState(errorMessage: 'Failed to send recovery email')); // Emit error if recovery fails
    }
  }

  // Logout and Force Light Mode
  Future<void> signOut() async {
    try {

      emit(state.copyWith(isLoading: true));

      await _firebaseAuth.signOut();
      themeProvider.setLightMode();

      emit(AuthState(successMessage: "Signed out successfully", user: null));
    } catch (e) {
      emit(AuthState(errorMessage: "Error signing out: $e"));
    }
  }

  Future<void> deleteAccount() async {
    User? user = _firebaseAuth.currentUser;

    if (user != null) {

      await DatabaseService().deleteUserInfoFromFirebase(user.uid);

      await user.delete();
    }
  }

}
