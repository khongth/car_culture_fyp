import 'package:flutter/material.dart';

class MyBioBox extends StatelessWidget {

  final String text;

  const MyBioBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(

      ),
      padding: const EdgeInsets.all(25),
      child: Text(
        text.isNotEmpty ? text : "No bio",
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontStyle: text.isNotEmpty ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}
