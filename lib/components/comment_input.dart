import 'package:flutter/material.dart';
import '../models/post.dart';

class CommentInputBox extends StatefulWidget {
  final TextEditingController textController;
  final Post post; // The original post being replied to
  final VoidCallback onPressed;
  final String onPressedText;

  const CommentInputBox({
    Key? key,
    required this.textController,
    required this.post,
    required this.onPressed,
    this.onPressedText = "Reply",
  }) : super(key: key);

  @override
  _CommentInputBoxState createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<CommentInputBox> {
  bool _isTextNotEmpty = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_checkText);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_checkText);
    super.dispose();
  }

  void _checkText() {
    setState(() {
      _isTextNotEmpty = widget.textController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 50),

          // Top Bar (Cancel, Reply)
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.textController.clear();
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Reply",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: TextButton(
                  onPressed: _isTextNotEmpty
                      ? () {
                    Navigator.pop(context);
                    widget.onPressed();
                    widget.textController.clear();
                  }
                      : null,
                  child: Text(
                    widget.onPressedText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _isTextNotEmpty
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Original Post + Connecting Line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/91388754?v=4'),
                  ),
                  Container(
                    width: 1,
                    height: (widget.post.message.length / 1 ).clamp(80.0, 200.0), // ✅ Dynamic height
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        children: [
                          TextSpan(
                            text: widget.post.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: " @${widget.post.username} · 5m",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.post.message,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          //Your reply input box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 1,
                    height: 25, // Properly connects both profile pictures
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://avatars.githubusercontent.com/u/91388754?v=4', // Your profile picture
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Replying to @${widget.post.username}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    TextField(
                      controller: widget.textController,
                      maxLength: 280,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText: "Post your reply...",
                        hintStyle: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.secondary),
                      ),
                      style: const TextStyle(fontSize: 18),
                      onChanged: (text) {
                        setState(() {}); // Refresh UI for reply button enable/disable
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Media Attachments
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.image, size: 28, color: Theme.of(context).colorScheme.primary),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.gif, size: 28, color: Theme.of(context).colorScheme.primary),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.poll, size: 28, color: Theme.of(context).colorScheme.primary),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
