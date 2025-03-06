import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  final String animationPath;
  final String? loadingText;

  const LoadingScreen({
    Key? key,
    this.animationPath = 'assets/animations/loading.json', // Default animation
    this.loadingText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animationPath, width: 150, height: 150),
          if (loadingText != null) // Show text only if provided
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                loadingText!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
