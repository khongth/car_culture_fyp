import 'package:car_culture_fyp/components/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../components/loading_screen.dart';
import '../home/home_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/text_field.dart';
import '../components/user_post.dart';
import '../components/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      textController = TextEditingController();
      context.read<HomeCubit>().fetchPosts();
    });
  }
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          print("Current state detected in listener: $state");
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
            ));
          }
          if (state is HomeSignedOut) {
            print("HomeSignedOut state detected, navigating to login...");
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return LoadingScreen();
          }

          if (state is HomeLoaded) {
            return Center(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.posts.length,
                      itemBuilder: (context, index) {
                        final post = state.posts[index];
                        return UserPost(
                          message: post["message"],
                          user: post["user"],
                          time: post["time"],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: MyTextField(
                            controller: textController,
                            hintText: "Share something here!",
                            obscureText: false,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.read<HomeCubit>().postMessage(textController.text);
                            textController.clear();
                          },
                          icon: Icon(
                            Icons.arrow_circle_up_rounded,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),

    );
  }
}


