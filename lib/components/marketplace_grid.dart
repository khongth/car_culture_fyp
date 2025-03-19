import 'package:flutter/material.dart';
import '../helper/navigatet_pages.dart';
import '../models/marketplace.dart';
import 'marketplace_tile.dart';

class MarketplaceGrid extends StatelessWidget {
  final List<MarketplacePost> posts;

  const MarketplaceGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return MarketplaceTile(
          post: posts[index],
          onTap: () => goMarketplaceItemPage(context, posts[index]),
        );
      },
    );
  }
}