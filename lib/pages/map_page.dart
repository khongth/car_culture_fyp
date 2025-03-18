import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class MapPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  const MapPage({super.key, this.onDrawerOpen});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(3.1390, 101.6869);
  final List<CarEvent> _events = [];
  bool _isLoading = true;

  CarEvent? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await Future.delayed(const Duration(milliseconds: 500)); //Network delay

    final List<CarEvent> events = [
      CarEvent(
        id: '1',
        name: 'KL Auto Salon 2025',
        location: 'Kuala Lumpur Convention Centre',
        description: 'The biggest auto show in Malaysia featuring custom cars and the latest models.',
        date: DateTime(2025, 3, 20),
        position: const LatLng(3.1536, 101.7153),
      ),
      CarEvent(
        id: '2',
        name: 'JDM Meetup Putrajaya',
        location: 'IOI City Mall',
        description: 'Japanese car enthusiasts gathering with competitions and exhibitions.',
        date: DateTime(2025, 3, 25),
        position: const LatLng(2.9713, 101.7158),
      ),
      CarEvent(
        id: '3',
        name: 'Penang Classic Car Showcase',
        location: 'Gurney Plaza',
        description: 'Vintage and classic cars on display with history of Malaysian automotive culture.',
        date: DateTime(2025, 4, 5),
        position: const LatLng(5.4382, 100.3089),
      ),
      CarEvent(
        id: '4',
        name: 'Malaysia Autoshow 2025',
        location: 'MAEPS, Serdang',
        description: 'Annual auto show featuring the latest car models and automotive technology.',
        date: DateTime(2025, 4, 12),
        position: const LatLng(2.9778, 101.7068),
      ),
      CarEvent(
        id: '5',
        name: 'Johor Drift Championship',
        location: 'Johor Circuit',
        description: 'Professional drifting competition with exhibitions and meet-and-greet sessions.',
        date: DateTime(2025, 4, 18),
        position: const LatLng(1.5853, 103.6254),
      ),
    ];

    setState(() {
      _events.addAll(events);
      _isLoading = false;
      _updateMarkers();
    });
  }

  final Set<Marker> _markers = {};

  void _updateMarkers() {
    final Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId("currentLocation"),
        position: _initialPosition,
        infoWindow: const InfoWindow(title: "Current Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    for (final event in _events) {
      markers.add(
        Marker(
          markerId: MarkerId("event_${event.id}"),
          position: event.position,
          infoWindow: InfoWindow(title: event.name),
          icon: _selectedEvent?.id == event.id
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _selectEvent(event);
          },
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(null);
  }

  void _selectEvent(CarEvent event) {
    setState(() {
      _selectedEvent = event;
      _updateMarkers();
    });

    //Animate camera to the selected event
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: event.position,
          zoom: 15.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Events Map"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            if (widget.onDrawerOpen != null) {
              widget.onDrawerOpen!();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 10.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            liteModeEnabled: false, //True for low-end devices
          ),

          //Bottom sheet for events list
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Car Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_events.length} events',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _events.isEmpty
                          ? const Center(child: Text('No upcoming events'))
                          : ListView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final isSelected = _selectedEvent?.id == event.id;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue.shade50 : null,
                            child: InkWell(
                              onTap: () => _selectEvent(event),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //Date icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('d').format(event.date),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM').format(event.date),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    //Event details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  event.location,
                                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            event.description,
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    //Navigation icon
                                    Icon(
                                      Icons.navigate_next,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
