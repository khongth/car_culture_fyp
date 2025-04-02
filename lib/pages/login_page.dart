import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import 'package:flutter_login/flutter_login.dart';
import '../components/loading_screen.dart';
import '../themes/theme_provider.dart';

class LoginPage extends StatelessWidget {
  final String adminUid = 'u8VmTy8ar2hMRtNfZUZsqfI1Bx03';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(Provider.of<ThemeProvider>(context, listen: false),),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
              ));
              Navigator.pushReplacementNamed(context, '/login');
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.successMessage!),
              ));
              if (state.successMessage == "Login successful" ||
                  state.successMessage == "Signup successful") {
                if (state.user?.uid == adminUid) {
                  // If the user is the admin, redirect to AdminPage
                  Navigator.pushReplacementNamed(context, '/admin');
                } else {
                  // Otherwise, go to the home page for regular users
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return LoadingScreen();
            }

            return FlutterLogin(
              logo: AssetImage("assets/images/CarCultureLogo.png"),
              onLogin: (data) {
                context.read<AuthCubit>().login(data.name, data.password);  // Login using Cubit
                context.read<AuthCubit>().fetchUser();
                return null;
              },
              onSignup: (data) {
                context.read<AuthCubit>().signUp(data.name!, data.password!);  // Signup using Cubit
                return null;
              },
              onRecoverPassword: (email) {
                context.read<AuthCubit>().recoverPassword(email);  // Recover password using Cubit
                return null;
              },
              loginAfterSignUp: true,
            );
          },
        ),
      ),
    );
  }
}
