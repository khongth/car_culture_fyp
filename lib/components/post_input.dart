import 'package:flutter/material.dart';

class PostInputBox extends StatefulWidget {
  final TextEditingController textController;
  final String hintText;
  final VoidCallback onPressed;
  final String onPressedText;

  const PostInputBox({
    Key? key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    this.onPressedText = "Post",
  }) : super(key: key);

  @override
  _PostInputBoxState createState() => _PostInputBoxState();
}

class _PostInputBoxState extends State<PostInputBox> {
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

          Stack(
            alignment: Alignment.center,
            children: [
              //Cancel Button
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

              //"New Post"
              Center(
                child: Text(
                  "New Post",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),

              //Post Button
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
                          ? Theme.of(context).colorScheme.inversePrimary // Enabled
                          : Theme.of(context).colorScheme.secondary, // Disabled
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 8, left: 10),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    'https://avatars.githubusercontent.com/u/91388754?v=4',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              //Text Input
              Expanded(
                child: TextField(
                  controller: widget.textController,
                  maxLength: 280,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          //Media Attachments
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
              Spacer(),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
