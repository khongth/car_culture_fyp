import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/marketplace.dart';
import '../components/marketplace_grid.dart';
import '../services/database_provider.dart';

class MarketplaceSearchPage extends StatelessWidget {
  final String searchQuery;

  const MarketplaceSearchPage({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final searchResults = Provider.of<DatabaseProvider>(context).marketplaceSearchResult;

    return Scaffold(
      appBar: AppBar(
        title: Text("Search Results: $searchQuery"),
      ),
      body: searchResults.isEmpty
          ? const Center(child: Text("No matching items found."))
          : MarketplaceGrid(posts: searchResults),
    );
  }
}
