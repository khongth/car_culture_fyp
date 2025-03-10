import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final User? user;
  final String? username;

  AuthState({
    this.isLoading = false,
    this.username,
    this.successMessage,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    User? user,
    String? username,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      user: user ?? this.user,
      username: username ?? this.username,
    );
  }
}
