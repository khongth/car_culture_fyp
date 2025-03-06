import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../themes/theme_provider.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ThemeProvider themeProvider; // ✅ Ensure this is initialized

  AuthCubit(this.themeProvider) : super(AuthState(user: FirebaseAuth.instance.currentUser)) {
    fetchUser();
  }

  void fetchUser() async {
    User? user = _firebaseAuth.currentUser;

    if (user != null) {
      await user.reload(); // ✅ Ensure the latest user data is fetched from Firebase
      user = _firebaseAuth.currentUser; // Get updated user object

      emit(AuthState(user: user)); // ✅ Emit updated user info
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
        if (user.displayName == null || user.displayName!.isEmpty) { // ✅ Check if display name is missing
          String username = email.split('@')[0]; // ✅ Extract username from email
          await user.updateDisplayName(username); // ✅ Set display name
          await user.reload(); // Refresh user data
        }

        fetchUser(); // ✅ Fetch user info after login
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
      User? user = userCredential.user;
      await user?.updateDisplayName("New User");

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
      themeProvider.setLightMode(); // ✅ Force light mode on sign out

      emit(AuthState(successMessage: "Signed out successfully", user: null));
    } catch (e) {
      emit(AuthState(errorMessage: "Error signing out: $e"));
    }
  }
}
