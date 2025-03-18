import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isCurrentUser;
  final String? imageUrl;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Limits width dynamically
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blueGrey.shade300 : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isCurrentUser ? const Radius.circular(12) : Radius.zero,
              bottomRight: isCurrentUser ? Radius.zero : const Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              // Show image if available
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    width: 200, // Adjust this size as per your requirement
                    height: 200, // Adjust this size as per your requirement
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8), // Space between the image and message

              // Message text (auto-expands)
              Text(
                message,
                softWrap: true,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8), // Space before timestamp

              // Timestamp (keeps its position at the end)
              Text(
                timestamp,
                style: TextStyle(
                  color: isCurrentUser ? Colors.grey.shade300 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
