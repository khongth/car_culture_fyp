import 'package:flutter/material.dart';
import '../helper/navigatet_pages.dart';
import '../models/marketplace.dart';
import '../pages/marketplace_item_page.dart';
import 'marketplace_tile.dart';

class MarketplaceRecentListings extends StatelessWidget {
  final List<MarketplacePost> posts;

  const MarketplaceRecentListings({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 225,
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return MarketplaceTile(
            post: posts[index],
            onTap: () {
              // Using PageRouteBuilder to create a slide-in transition
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return MarketplaceItemPage(
                      post: posts[index],
                      onClose: () => Navigator.pop(context),
                    );
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
