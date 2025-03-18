import 'dart:io';

import 'package:car_culture_fyp/components/chat_bubble.dart';
import 'package:car_culture_fyp/components/message_input.dart';
import 'package:car_culture_fyp/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {

  final String receiverEmail;
  final String receiverId;
  const ChatPage({super.key, required this.receiverEmail, required this.receiverId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final DatabaseService _databaseService = DatabaseService();
  final _auth = FirebaseAuth.instance;

  FocusNode myFocusNode = FocusNode();

  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;

  void sendMessage() async {
    if (_messageController.text.trim().isNotEmpty || _selectedImage != null) {
      await _databaseService.sendMessage(
          widget.receiverId,
          _messageController.text.trim(),
          imageFile: _selectedImage
      );

      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
    }

    scrollDown();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void removeImage() {
    setState(() {
      _selectedImage = null;  // Remove the selected image
    });
  }
  
  @override
  void initState() {
    super.initState();
    
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 500),
            () => scrollDown(),
        );
      }
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverEmail)),
      body: Column(
        children: [
          //Display all messages
          Expanded(child: _buildMessageList()),

          //User input
          _buildUserInput()
        ],
      ),
    );
  }


  Widget _buildMessageList() {
    String senderId = _auth.currentUser!.uid;
    return StreamBuilder(
      stream: _databaseService.getMessages(widget.receiverId, senderId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        return ListView(
          controller: _scrollController,
          reverse: true,
          children:
            snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      });
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('hh:mm a').format(dateTime); // e.g., "10:30 AM"

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data['message'],
            isCurrentUser: isCurrentUser,
            timestamp: formattedTime,
            imageUrl: data['imageUrl'],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserInput() {
    return Row(
      children: [
        Expanded(
          child: MessageInput(
            focusNode: myFocusNode,
            controller: _messageController,
            onSend: () {
              sendMessage();
            },
            onMediaUpload: _pickImage,
            selectedImage: _selectedImage,
            removeImage: removeImage,
          )
        )
      ],
    );
  }
}
