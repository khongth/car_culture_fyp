import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../services/database_provider.dart';

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

  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final _auth = FirebaseAuth.instance;

  // Creator ID - only this user can add events
  final String _creatorId = 'YSXNfj4jEtTQUA12Yyw66xc0Bhv2';

  CarEvent? _selectedEvent;
  final ValueNotifier<double> _sheetProgress = ValueNotifier(0.4);
  final DraggableScrollableController _scrollController = DraggableScrollableController();

  // Sheet thresholds
  final double _minSheetSize = 0.25;
  final double _initialSheetSize = 0.4;
  final double _maxSheetSize = 0.75;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Check if current user is the creator
  bool get _isCreator {
    final user = _auth.currentUser;
    return user != null && user.uid == _creatorId;
  }

  Future<void> _loadEvents() async {
    await databaseProvider.loadCarEvents();
    _updateMarkers();
  }

  final Set<Marker> _markers = {};

  void _updateMarkers() {
    final List<CarEvent> events = databaseProvider.carEvents;
    final Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId("currentLocation"),
        position: _initialPosition,
        infoWindow: const InfoWindow(title: "Current Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    for (final event in events) {
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

    _scrollController.animateTo(
      0.25,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Add a new car event
  Future<void> _addCarEvent(String name, String location, String description, DateTime date, LatLng position) async {
    await databaseProvider.addCarEvent(name, location, description, date, position);
    await _loadEvents();
  }

  void _showAddEventSheet(BuildContext context) {
    // Only allow the creator to add events
    if (!_isCreator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not authorized to add events')),
      );
      return;
    }

    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    LatLng selectedPosition = _initialPosition;
    bool isLocationSelected = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Car Event',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          List<Location> locations = await locationFromAddress(
                            locationController.text,
                          );
                          if (locations.isNotEmpty) {
                            setState(() {
                              selectedPosition = LatLng(
                                locations.first.latitude,
                                locations.first.longitude,
                              );
                              isLocationSelected = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location found!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not find the location'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Find Location'),
                    ),
                    if (isLocationSelected) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: selectedPosition,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: selectedPosition,
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              locationController.text.isEmpty ||
                              descriptionController.text.isEmpty ||
                              !isLocationSelected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields and select a location'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          _addCarEvent(
                            nameController.text,
                            locationController.text,
                            descriptionController.text,
                            selectedDate,
                            selectedPosition,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text('Add Event'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = databaseProvider.carEvents;

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
        actions: [
          // Only show the add button if the current user is the creator
          if (_isCreator)
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              onPressed: () => _showAddEventSheet(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map layer
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 10.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            liteModeEnabled: false,
          ),

          ValueListenableBuilder<double>(
            valueListenable: _sheetProgress,
            builder: (context, sheetHeight, child) {
              double bottomPosition = (MediaQuery.of(context).size.height * sheetHeight).clamp(10, 200);

              return Positioned(
                bottom: bottomPosition < 16 ? 16 : bottomPosition,
                right: 16,
                child: FloatingActionButton(
                  elevation: 2,
                  onPressed: _returnToCurrentLocation,
                  backgroundColor: Colors.blueGrey.withOpacity(0.7),
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              );
            },
          ),

          // Sheet layer - positioned AFTER the FAB so it can cover it
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _sheetProgress.value = notification.extent;
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _scrollController,
              initialChildSize: _initialSheetSize,
              minChildSize: _minSheetSize,
              maxChildSize: _maxSheetSize,
              builder: (context, scrollController) {
                final events = Provider.of<DatabaseProvider>(context).carEvents;
                final isLoading = Provider.of<DatabaseProvider>(context).isLoadingEvents;

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
                      // Drag handle
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
                              '${events.length} events',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : events.isEmpty
                            ? const Center(child: Text('No upcoming events'))
                            : ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            final isSelected = _selectedEvent?.id == event.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
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
                                      // Date icon
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

                                      // Event details
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

                                      // Navigation icon
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

          ),
        ],
      ),
    );
  }

  void _returnToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
      ),
    );
  }
}