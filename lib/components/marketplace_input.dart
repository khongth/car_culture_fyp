import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MarketplaceInputBox extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final VoidCallback onPost;
  final Function(List<File>) onImageSelected;

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
  List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
      widget.onImageSelected(_selectedImages);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImageSelected(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 50,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Marketplace Item',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (RM)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Select Images'),
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              padding: const EdgeInsets.all(5),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.titleController.text.isEmpty ||
                      widget.descriptionController.text.isEmpty ||
                      widget.priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  widget.onPost();
                  Navigator.pop(context);
                },
                child: const Text('Add Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
