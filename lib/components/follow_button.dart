import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {

  final bool isFollowing;
  final void Function()? onPressed;
  
  const FollowButton({
    super.key,
    required this.onPressed,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MaterialButton(
          elevation: 0,
          padding: EdgeInsets.only(left: 50, right: 50, top: 5, bottom: 5),
          onPressed: onPressed,

          color:
            isFollowing? Colors.grey.shade500 : Colors.blue.shade600,

          child: Text(
            isFollowing ? "Unfollow" : "Follow",
            style: TextStyle(color: Colors.white),
          ),

        ),
      ),
    );
  }
}
