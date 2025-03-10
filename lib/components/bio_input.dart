import 'package:flutter/material.dart';

class BioInputBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final VoidCallback onPressed;
  final String onPressedText;

  const BioInputBox({
    Key? key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    this.onPressedText = "Save",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ✅ Add consistent padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Adjust to content size
        children: [
          // ✅ Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // ✅ Ensure buttons and title are aligned
            children: [
              // ✅ Cancel Button (Left)
              TextButton(
                style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),

              // ✅ Center Title
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Edit Bio",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ),

              TextButton(
                style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
                onPressed: () {
                  Navigator.pop(context);

                  onPressed();

                  textController.clear();
                },
                child: Text(
                  onPressedText,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16), // ✅ Increased spacing for better balance

          // ✅ Text Input Field
          TextField(
            controller: textController,
            maxLength: 140,
            maxLines: 3,
            decoration: InputDecoration(
              counterStyle: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20), // ✅ Increased spacing for better separation
        ],
      ),
    );
  }
}
