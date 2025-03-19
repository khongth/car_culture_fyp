import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplacePost {
  final String id;
  final String uid;
  final String title;
  final String description;
  final double price;
  final List<String>? imageUrls;
  final dynamic timestamp;

  MarketplacePost({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.price,
    required this.timestamp,
    this.imageUrls,
  });

  // Convert Firestore > MarketplacePost object
  factory MarketplacePost.fromDocument(DocumentSnapshot doc) {
    return MarketplacePost(
      id: doc.id,
      uid: doc['uid'],
      title: doc['title'],
      description: doc['description'],
      price: doc['price'].toDouble(),
      timestamp: doc['timestamp'],
      imageUrls: List<String>.from(doc['imageUrls'] ?? []),
    );
  }

  // Convert MarketplacePost object > map > Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'price': price,
      'timestamp': timestamp,
      'imageUrls': imageUrls ?? [],
    };
  }
}