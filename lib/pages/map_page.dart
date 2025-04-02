import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../services/database_provider.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final VoidCallback? onDrawerOpen;
  const MapPage({super.key, this.onDrawerOpen});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  LatLng? _initialPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  late DatabaseProvider databaseProvider;
  late final _auth = FirebaseAuth.instance;

  final String _creatorId = '3MBGKQAPbANUSCzImOomi3vkE1C3';

  CarEvent? _selectedEvent;
  final ValueNotifier<double> _sheetProgress = ValueNotifier(0.4);
  final DraggableScrollableController _scrollController = DraggableScrollableController();

  final double _minSheetSize = 0.25;
  final double _initialSheetSize = 0.4;
  final double _maxSheetSize = 0.75;

  bool _sortByDistance = false;
  bool _showPastEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      await databaseProvider.loadBookmarkedEvents(); // <-- Load bookmarks from Firestore
      await _getCurrentLocation();
      await _loadEvents();
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (mounted && _initialPosition != null) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 14));
        _updateMarkers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isCreator {
    final user = _auth.currentUser;
    return user != null && user.uid == _creatorId;
  }

  Future<void> _toggleBookmark(String eventId) async {
    await databaseProvider.toggleBookmarkEvent(eventId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          databaseProvider.isEventBookmarked(eventId)
              ? 'Event bookmarked'
              : 'Bookmark removed',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    _updateMarkers();
    setState(() {}); // To reorder the list
  }

  bool _isBookmarked(String eventId) =>
      databaseProvider.isEventBookmarked(eventId);

  Future<void> _loadEvents() async {
    if (!mounted) return;

    try {
      await databaseProvider.loadCarEvents();
      if (mounted) {
        _updateMarkers();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${e.toString()}')),
        );
      }
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) =>
      Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);

  String _formatDistance(double meters) =>
      meters < 1000 ? '${meters.toStringAsFixed(0)} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  String _estimateTravelTime(double meters) {
    double timeInMinutes = (meters / 1000) / 40 * 60;
    if (timeInMinutes < 1) return '<1 min';
    if (timeInMinutes < 60) return '${timeInMinutes.round()} min';
    final h = timeInMinutes ~/ 60, m = (timeInMinutes % 60).round();
    return '${h}h ${m}m';
  }

  void _updateMarkers() {
    if (!mounted) return;

    final now = DateTime.now();
    List<CarEvent> events = databaseProvider.carEvents
        .where((e) => _showPastEvents ? e.date.isBefore(now) : (e.date.isAfter(now) || _isToday(e.date)))
        .toList();

    final Set<Marker> markers = {};
    if (_initialPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _initialPosition!,
        infoWindow: const InfoWindow(title: "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    for (final event in events) {
      markers.add(
        Marker(
          markerId: MarkerId("event_${event.id}"),
          position: event.position,
          infoWindow: InfoWindow(title: event.name),
          icon: _selectedEvent?.id == event.id
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _selectEvent(event),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  List<CarEvent> _getSortedEvents() {
    final now = DateTime.now();
    List<CarEvent> filtered = databaseProvider.carEvents.where((event) {
      return _showPastEvents ? event.date.isBefore(now) : (event.date.isAfter(now) || _isToday(event.date));
    }).toList();

    filtered.sort((a, b) {
      final aBookmarked = _isBookmarked(a.id);
      final bBookmarked = _isBookmarked(b.id);
      if (aBookmarked != bBookmarked) return aBookmarked ? -1 : 1;

      if (_sortByDistance && _initialPosition != null) {
        return _calculateDistance(_initialPosition!, a.position)
            .compareTo(_calculateDistance(_initialPosition!, b.position));
      }

      return a.date.compareTo(b.date);
    });

    return filtered;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_initialPosition != null) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 14));
    }
  }

  void _selectEvent(CarEvent event) {
    setState(() => _selectedEvent = event);
    _updateMarkers();

    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: event.position, zoom: 15.0),
    ));

    _scrollController.animateTo(_minSheetSize,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _returnToCurrentLocation() {
    if (_initialPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: _initialPosition!,
          zoom: 14.0,
        )),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _addCarEvent(String name, String location, String description, DateTime date, LatLng position) async {
    try {
      await databaseProvider.addCarEvent(name, location, description, date, position);
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add event: ${e.toString()}')),
        );
      }
    }
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
    LatLng? selectedPosition = _initialPosition;
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
                    if (isLocationSelected && selectedPosition != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: selectedPosition!,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: selectedPosition!,
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
                              !isLocationSelected ||
                              selectedPosition == null) {
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
                            selectedPosition!,
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initialPosition == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text("Unable to get location"),
              SizedBox(height: 8),
              Text("Please enable location services and try again",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Events Map"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onDrawerOpen,
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
              target: _initialPosition!,
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
                final events = _getSortedEvents();
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
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Upcoming'),
                                  selected: !_showPastEvents,
                                  onSelected: (selected) {
                                    setState(() {
                                      _showPastEvents = false;
                                      _updateMarkers();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Past'),
                                  selected: _showPastEvents,
                                  onSelected: (selected) {
                                    setState(() {
                                      _showPastEvents = true;
                                      _updateMarkers();
                                    });
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_initialPosition != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.sort,
                                      color: _sortByDistance ? Colors.blue : Colors.grey,
                                    ),
                                    tooltip: 'Sort by distance',
                                    onPressed: () {
                                      setState(() {
                                        _sortByDistance = !_sortByDistance;
                                      });
                                    },
                                  ),
                                Text(
                                  '${events.length} events',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : events.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    _showPastEvents ? Icons.history : Icons.event_busy,
                                    size: 48,
                                    color: Colors.grey
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showPastEvents ? 'No past events' : 'No upcoming events',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                              : ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final isSelected = _selectedEvent?.id == event.id;

                              // Calculate distance if user location is available
                              String distanceText = 'Distance unavailable';
                              String travelTimeText = 'Time unavailable';

                              if (_initialPosition != null) {
                                final distance = _calculateDistance(_initialPosition!, event.position);
                                distanceText = _formatDistance(distance);
                                travelTimeText = _estimateTravelTime(distance);
                              }

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
                                        // Date icon (unchanged)
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
                                              Row(
                                                children: [
                                                  const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    distanceText,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    travelTimeText,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
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
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      _isBookmarked(event.id) ? Icons.bookmark : Icons.bookmark_border,
                                                      color: _isBookmarked(event.id) ? Colors.orange : Colors.grey,
                                                    ),
                                                    onPressed: () => _toggleBookmark(event.id),
                                                    tooltip: _isBookmarked(event.id) ? 'Remove bookmark' : 'Bookmark this event',
                                                  ),
                                                ],
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
                          )
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
}
