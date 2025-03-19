import 'package:flutter/material.dart';
import '../models/marketplace.dart';

class MarketplaceTile extends StatelessWidget {
  final MarketplacePost post;
  final VoidCallback? onTap;

  const MarketplaceTile({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get the first image from the list, if available
    String? thumbnailImage =
    (post.imageUrls != null && post.imageUrls!.isNotEmpty)
        ? post.imageUrls!.first
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Stack(
              children: [
                thumbnailImage != null
                    ? Image.network(
                  thumbnailImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                )
                    : _buildPlaceholder(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              "RM ${post.price.toStringAsFixed(2)} • ${post.title}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }
}
