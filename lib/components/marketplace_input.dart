import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MarketplaceInputBox extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final VoidCallback onPost;
  final Function(File?) onImageSelected;

  const MarketplaceInputBox({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.onPost,
    required this.onImageSelected,
  });

  @override
  _MarketplaceInputBoxState createState() => _MarketplaceInputBoxState();
}

class _MarketplaceInputBoxState extends State<MarketplaceInputBox> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      widget.onImageSelected(_selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: widget.titleController, decoration: InputDecoration(labelText: "Title")),
        TextField(controller: widget.descriptionController, decoration: InputDecoration(labelText: "Description"), maxLines: 3),
        TextField(controller: widget.priceController, decoration: InputDecoration(labelText: "Price (RM)"), keyboardType: TextInputType.number),
        if (_selectedImage != null)
          Image.file(_selectedImage!, width: 100, height: 100),
        Row(
          children: [
            IconButton(icon: Icon(Icons.image), onPressed: _pickImage),
            ElevatedButton(onPressed: widget.onPost, child: Text("Post")),
          ],
        ),
      ],
    );
  }
}