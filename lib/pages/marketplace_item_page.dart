import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../auth/auth_cubit.dart';
import '../components/marketplace_recent_listings.dart';
import '../components/user_list_tile.dart';
import '../helper/navigatet_pages.dart';
import '../models/marketplace.dart';
import '../models/user.dart';
import '../services/database_provider.dart';
import 'marketplace_page.dart';

class MarketplaceItemPage extends StatefulWidget {
  final MarketplacePost post;
  final VoidCallback onClose;

  const MarketplaceItemPage({Key? key, required this.post, required this.onClose}) : super(key: key);

  @override
  State<MarketplaceItemPage> createState() => _MarketplaceItemPageState();
}

class _MarketplaceItemPageState extends State<MarketplaceItemPage> {
  UserProfile? _sellerProfile;
  List<MarketplacePost> _allListings = [];

  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
    _loadRecentListings();
  }

  Future<void> _loadSellerInfo() async {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final seller = await databaseProvider.userProfile(widget.post.uid);
    setState(() {
      _sellerProfile = seller;
    });
  }

  Future<void> _loadRecentListings() async {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    await databaseProvider.loadMarketplacePosts(); // Ensure you're calling this method to fetch data

    setState(() {
      // Exclude the current post from the recent listings
      _allListings = databaseProvider.marketplacePosts
          .where((post) => post.id != widget.post.id) // Exclude the current post by ID
          .toList(); // Update the state with the filtered data
    });
  }

  void _showOptions() {
    String? currentUserId = context.read<AuthCubit>().state.user?.uid;
    final bool isOwnPost = widget.post.uid == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isOwnPost)
                ListTile(
                  leading: const Icon(IconlyBold.delete),
                  title: const Text("Delete"),
                  onTap: () async {
                    Navigator.pop(context);
                    widget.onClose();
                    await databaseProvider.deleteMarketplacePost(widget.post.id);
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Report"),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPostConfirmationBox();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block User"),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUserConfirmationBox();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Report Post Dialog
  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Message"),
        content: const Text("Are you sure you want to report this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await databaseProvider.reportUser(widget.post.id, widget.post.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message reported!")));
            },
            child: Text(
              "Report",
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          )
        ],
      ),
    );
  }

  // Block User Dialog
  void _blockUserConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Block User"),
        content: const Text("Are you sure you want to block this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await databaseProvider.blockUser(widget.post.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Blocked!")));
            },
            child: Text(
              "Block",
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Details"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz),
            onPressed: _showOptions, // Show options menu
          )
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 10),
            _buildItemDetails(),
            const SizedBox(height: 10),
            _buildSellerInfo(),
            const Spacer(),
            _buildRecentListings(),
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
        onUserTap: (uid) => goUserPage(context, uid)
    );
  }

  Widget _buildRecentListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Recent Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        MarketplaceRecentListings(posts: _allListings),
      ],
    );
  }

}
