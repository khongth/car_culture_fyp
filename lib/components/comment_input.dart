import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/database_provider.dart';

class CommentInputBox extends StatefulWidget {
  final TextEditingController textController;
  final Post post;
  final VoidCallback onPressed;
  final Function(File?) onImageSelected;
  final String onPressedText;

  const CommentInputBox({
    Key? key,
    required this.textController,
    required this.post,
    required this.onPressed,
    required this.onImageSelected,
    this.onPressedText = "Reply",
  }) : super(key: key);

  @override
  State<CommentInputBox> createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<CommentInputBox> {
  bool _isTextNotEmpty = false;
  File? _imageFile;
  final _picker = ImagePicker();
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  UserProfile? _user;
  UserProfile? _currentUser;
  bool _isLoading = true;

  // Default fallback avatar
  static const String _defaultAvatarUrl = 'https://avatars.githubusercontent.com/u/91388754?v=4';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCurrentUser();
    widget.textController.addListener(_checkText);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_checkText);
    super.dispose();
  }

  void _checkText() {
    final bool hasContent = widget.textController.text.trim().isNotEmpty || _imageFile != null;
    if (_isTextNotEmpty != hasContent) {
      setState(() {
        _isTextNotEmpty = hasContent;
      });
    }
  }

  Future<void> _loadUser() async {
    try {
      final userProfile = await databaseProvider.userProfile(widget.post.uid);
      setState(() {
        _user = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Get the current user's UID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final currentUserProfile = await databaseProvider.userProfile(currentUser.uid);
        setState(() {
          _currentUser = currentUserProfile;
        });
      }
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Slightly compress images for better performance
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isTextNotEmpty = true;
        });

        widget.onImageSelected(_imageFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _isTextNotEmpty = widget.textController.text.trim().isNotEmpty;
    });

    widget.onImageSelected(null);
  }

  // Helper method to get avatar widget
  Widget _buildAvatar(String? url, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url ?? _defaultAvatarUrl),
      backgroundColor: Colors.grey[300],
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar: $exception');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isSmallScreen ? 30.0 : 50.0),

            // Top Bar (Cancel, Reply)
            _buildTopBar(colorScheme),

            SizedBox(height: isSmallScreen ? 16.0 : 24.0),

            // Original Post + Connecting Line
            _buildOriginalPost(colorScheme),

            // Reply Input Box
            _buildReplyInput(colorScheme),

            SizedBox(height: isSmallScreen ? 8.0 : 12.0),

            // Image Preview Section
            if (_imageFile != null)
              _buildImagePreview(),

            // Media Attachments
            _buildMediaAttachments(colorScheme),

            SizedBox(height: isSmallScreen ? 12.0 : 20.0),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
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
                color: colorScheme.secondary,
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
              color: colorScheme.inversePrimary,
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
              _removeImage();
            }
                : null,
            child: Text(
              widget.onPressedText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isTextNotEmpty
                    ? colorScheme.inversePrimary
                    : colorScheme.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPost(ColorScheme colorScheme) {
    final lineHeight = (widget.post.message.length / 1).clamp(80.0, 260.0) + (widget.post.imageUrl != null ? 300.0 : 0.0);
    final avatarRadius = MediaQuery.of(context).size.width < 400 ? 18.0 : 20.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildAvatar(_user?.profileImageUrl, avatarRadius),
            Container(
              width: 1,
              height: lineHeight,
              color: colorScheme.primary,
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
                    color: colorScheme.inversePrimary,
                  ),
                  children: [
                    TextSpan(
                      text: widget.post.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " @${widget.post.username} · 5m",
                      style: TextStyle(color: colorScheme.tertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.post.message,
                style: TextStyle(fontSize: 16, color: colorScheme.inversePrimary),
              ),
              if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 300,  // Fixed width
                      height: 300, // Fixed height
                      child: Image.network(
                        widget.post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 300,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.broken_image, color: Colors.grey[600]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyInput(ColorScheme colorScheme) {
    final avatarRadius = MediaQuery.of(context).size.width < 400 ? 18.0 : 20.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 1,
              height: 25,
              color: colorScheme.primary,
            ),
            _buildAvatar(_currentUser?.profileImageUrl, avatarRadius),
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
                  color: colorScheme.tertiary,
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
                  hintStyle: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                      color: colorScheme.secondary
                  ),
                ),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final borderRadius = MediaQuery.of(context).size.width < 400 ? 8.0 : 12.0;
    final imageHeight = MediaQuery.of(context).size.width < 400 ? 150.0 : 200.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            _imageFile!,
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: _removeImage,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaAttachments(ColorScheme colorScheme) {
    final iconSize = MediaQuery.of(context).size.width < 400 ? 24.0 : 28.0;

    return Row(
      children: [
        IconButton(
          onPressed: _pickImage,
          icon: Icon(Icons.image, size: iconSize, color: colorScheme.primary),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.gif, size: iconSize, color: colorScheme.primary),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.poll, size: iconSize, color: colorScheme.primary),
        ),
        const Spacer(),
      ],
    );
  }
}