import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}
