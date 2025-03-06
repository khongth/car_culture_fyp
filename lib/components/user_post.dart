import 'package:flutter/material.dart';

class UserPost extends StatelessWidget {
  final String message;
  final String user;
  final String time;

  const UserPost({
    super.key,
    required this.message,
    required this.user,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.only(top: 10, left: 15, right: 15),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                user,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
