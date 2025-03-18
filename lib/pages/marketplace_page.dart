import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/marketplace.dart';
import '../components/marketplace_grid.dart';
import '../services/database_provider.dart';
import '../components/marketplace_input.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
  }

  void _showMarketplaceInputBox(BuildContext context) {
    File? selectedImage;

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
            onImageSelected: (File? image) {
              selectedImage = image;
            },
            onPost: () async {
              await postMarketplaceItem(
                _titleController.text.trim(),
                _descriptionController.text.trim(),
                double.tryParse(_priceController.text) ?? 0.0,
                selectedImage,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> postMarketplaceItem(String title, String description, double price, File? selectedImage) async {
    await databaseProvider.postMarketplaceItem(title, description, price, imageFile: selectedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search Marketplace...",
            border: InputBorder.none,
          ),
        )
            : Text("Marketplace"),
        leading: IconButton(
          icon: Icon(Icons.menu),
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
            icon: Icon(Icons.add, size: 28),
            onPressed: () => _showMarketplaceInputBox(context),
          ),
        ],
        bottom: TabBar(
          dividerColor: Theme.of(context).colorScheme.primary,
          controller: _tabController,
          labelColor: Colors.black, // Selected text color
          unselectedLabelColor: Colors.grey[500], // Unselected text color
          tabs: [
            Tab(text: "Your Listings"),
            Tab(text: "For You"),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Your Listings (empty for now)
          Center(child: Text("Your Listings is empty...")),

          // For You (Marketplace Grid)
          _buildMarketplaceGrid(listeningProvider.marketplacePosts),
        ],
      ),
    );
  }

  Widget _buildMarketplaceGrid(List<MarketplacePost> posts) {
    return posts.isEmpty
        ? Center(child: Text("No items for sale..."))
        : MarketplaceGrid(posts: posts);
  }
}
