import 'package:flutter/material.dart';

class MessageButton extends StatelessWidget {
  final void Function()? onPressed;

  const MessageButton({
    super.key,
    required this.onPressed,
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

          color: Colors.grey.shade500,

          child: Text(
            "Message",
            style: TextStyle(color: Colors.white),
          ),

        ),
      ),
    );
  }
}
