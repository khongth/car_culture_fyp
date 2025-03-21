import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/database_provider.dart';

class PostInputBox extends StatefulWidget {
  final TextEditingController textController;
  final String hintText;
  final VoidCallback onPressed;
  final String onPressedText;
  final Function(File?) onImageSelected;

  const PostInputBox({
    Key? key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    required this.onImageSelected,
    this.onPressedText = "Post",
  }) : super(key: key);

  @override
  _PostInputBoxState createState() => _PostInputBoxState();
}

class _PostInputBoxState extends State<PostInputBox> {
  bool _isTextNotEmpty = false;
  File? _selectedImage;
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  UserProfile? _user;
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    widget.textController.addListener(_checkText);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_checkText);
    super.dispose();
  }

  void _checkText() {
    setState(() {
      _isTextNotEmpty = widget.textController.text.trim().isNotEmpty || _selectedImage != null;
    });
  }

  Future<void> _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await databaseProvider.userProfile(currentUser!.uid);
    setState(() {
      _currentUser = userProfile;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isTextNotEmpty = true;
      });

      widget.onImageSelected(_selectedImage);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _isTextNotEmpty = widget.textController.text.trim().isNotEmpty;
    });

    widget.onImageSelected(null);
  }

  Widget _buildAvatar(String? url, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url ?? ''),
      backgroundColor: Colors.grey[300],
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar: $exception');
      },
    );
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
                    _removeImage();
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
                    _removeImage();
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
                child: _buildAvatar(_currentUser?.profileImageUrl, 20), // Use the profileImageUrl here
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

          if (_selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: _removeImage,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 10),

          //Media Attachments
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: Icon(Icons.image, size: 28, color: Theme.of(context).colorScheme.primary),
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

