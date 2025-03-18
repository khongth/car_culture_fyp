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
}