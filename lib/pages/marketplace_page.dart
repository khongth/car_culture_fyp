import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/marketplace.dart';
import '../components/marketplace_grid.dart';
import '../services/database_provider.dart';
import '../components/marketplace_input.dart';
import 'marketplace_search_page.dart';

class MarketplacePage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;

  const MarketplacePage({super.key, this.onDrawerOpen});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> with SingleTickerProviderStateMixin {
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadMarketplacePosts();
  }

  Future<void> loadMarketplacePosts() async {
    await databaseProvider.loadMarketplacePosts();
    await databaseProvider.loadYourMarketplaceListing();
  }

  void _showMarketplaceInputBox(BuildContext context) {
    List<File> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          child: MarketplaceInputBox(
            titleController: _titleController,
            descriptionController: _descriptionController,
            priceController: _priceController,
            onImageSelected: (List<File> images) {
              selectedImages = images;
            },
            onPost: () async {
              await postMarketplaceItem(
                _titleController.text.trim(),
                _descriptionController.text.trim(),
                double.tryParse(_priceController.text) ?? 0.0,
                selectedImages,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> postMarketplaceItem(String title, String description, double price, List<File> selectedImages) async {
    await databaseProvider.postMarketplaceItem(title, description, price, imageFiles: selectedImages);
    await loadMarketplacePosts(); // Reload posts after adding new item
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    await databaseProvider.searchMarketplace(query);

    // Push new page with slide-in animation
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300), // Animation speed
        pageBuilder: (context, animation, secondaryAnimation) => MarketplaceSearchPage(searchQuery: query),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Start position (right)
          const end = Offset.zero; // End position (center)
          const curve = Curves.easeInOut; // Smooth easing

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          onSubmitted: _performSearch,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search Marketplace...",
            border: InputBorder.none,
          ),
        )
            : const Text("Marketplace"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (widget.onDrawerOpen != null) {
              widget.onDrawerOpen!();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => _showMarketplaceInputBox(context),
          ),
        ],
        bottom: TabBar(
          dividerColor: Theme.of(context).colorScheme.primary,
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: "Your Listings"),
            Tab(text: "For You"),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarketplaceGrid(listeningProvider.youMarketplacePosts),

          _buildMarketplaceGrid(listeningProvider.marketplacePosts),
        ],
      ),
    );
  }

  Widget _buildMarketplaceGrid(List<MarketplacePost> posts) {
    return posts.isEmpty
        ? const Center(child: Text("No items for sale..."))
        : MarketplaceGrid(posts: posts);
  }
}
