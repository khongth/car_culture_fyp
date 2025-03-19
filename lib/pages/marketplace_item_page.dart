import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/user_list_tile.dart';
import '../helper/navigatet_pages.dart';
import '../models/marketplace.dart';
import '../models/user.dart';
import '../services/database_provider.dart';

class MarketplaceItemPage extends StatefulWidget {
  final MarketplacePost post;
  final VoidCallback onClose;

  const MarketplaceItemPage({Key? key, required this.post, required this.onClose}) : super(key: key);

  @override
  State<MarketplaceItemPage> createState() => _MarketplaceItemPageState();
}

class _MarketplaceItemPageState extends State<MarketplaceItemPage> {
  UserProfile? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final seller = await databaseProvider.userProfile(widget.post.uid);
    setState(() {
      _sellerProfile = seller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Details"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose, // Close post on back press
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 10),
            _buildItemDetails(),
            const SizedBox(height: 10),
            Divider(thickness: 1, color: Theme.of(context).colorScheme.primary),
            _buildSellerInfo(),
            Divider(thickness: 1, color: Theme.of(context).colorScheme.primary),
            _buildSimilarListings(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.post.imageUrls == null || widget.post.imageUrls!.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: widget.post.imageUrls!.length,
        itemBuilder: (context, index) {
          return Image.network(
            widget.post.imageUrls![index],
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "RM ${widget.post.price.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 18, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Text(widget.post.description),
          const SizedBox(height: 10),
          const Text("Category: Miscellaneous"),
          const Text("Location: Kuala Lumpur"),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    if (_sellerProfile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return UserListTile(
      uid: widget.post.uid,
      user: _sellerProfile!,
      onUserTap: (uid) => goUserPage(context, uid), // Calls goUserPage function
    );
  }

  Widget _buildSimilarListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Similar Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // TODO: Replace with actual similar listings
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 120,
                      child: Image.network("https://via.placeholder.com/120", fit: BoxFit.cover),
                    ),
                    const Text("Similar Item", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const Text("RM 80", style: TextStyle(fontSize: 14, color: Colors.green)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
