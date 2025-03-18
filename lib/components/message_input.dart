import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'dart:io'; // Import to handle File

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMediaUpload;
  final FocusNode? focusNode;
  final File? selectedImage;
  final VoidCallback removeImage;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onMediaUpload,
    this.focusNode,
    this.selectedImage,
    required this.removeImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          if (selectedImage != null)
          // Image preview section
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 100, // Adjust the size as needed
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      onPressed: removeImage,
                      icon: Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: TextField(
                    controller: controller,
                    maxLines: null, // Allows multi-line input
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "What's happening?",
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Media Upload Button (📎 Icon)
              IconButton(
                onPressed: onMediaUpload,
                icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
              ),

              // Send Button (📤 Icon)
              IconButton(
                onPressed: onSend,
                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
