import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarEvent {
  final String id;
  final String name;
  final String location;
  final String description;
  final DateTime date;
  final LatLng position;

  const CarEvent({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.date,
    required this.position,
  });

  // Convert Firestore > CarEvent object
  factory CarEvent.fromDocument(DocumentSnapshot doc) {
    GeoPoint geoPoint = doc['position'];
    return CarEvent(
      id: doc.id,
      name: doc['name'],
      location: doc['location'],
      description: doc['description'],
      date: (doc['date'] as Timestamp).toDate(),
      position: LatLng(geoPoint.latitude, geoPoint.longitude),
    );
  }

  // Convert CarEvent object > map > Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'date': Timestamp.fromDate(date),
      'position': GeoPoint(position.latitude, position.longitude),
    };
  }
}