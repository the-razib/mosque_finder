import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mosque_finder/services/mosque_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Google Maps Controller and related data
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _greenMarkerIcon;
  bool _isLoading = false;

  // User location and mosque data
  Position? _currentPosition;
  List<Map<String, dynamic>> _mosqueDetails = [];

  @override
  void initState() {
    super.initState();
    _initializeCustomMarker();
    _getCurrentLocation();
  }

  // MARK: - Initial Setup and Location Methods

  // Load custom marker icon
  Future<void> _initializeCustomMarker() async {
    _greenMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/mosque212.png', // Ensure this asset exists
    );
  }

  // Get the current location of the user
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        _showLocationError('Location permissions are denied.');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    _fetchNearbyMosques();
  }

  // Display location error message
  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // MARK: - Mosque Data Fetching and Management

  // Fetch nearby mosques using Google Places API
  Future<void> _fetchNearbyMosques() async {
    setState(() {
      _isLoading = true;
    });
    if (_currentPosition == null) return;

    List<Marker> mosqueMarkers = await MosqueService.fetchMosques(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _greenMarkerIcon,
    );

    setState(() {
      _markers.addAll(mosqueMarkers);
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      ),
    );

    _storeMosqueDetails(mosqueMarkers);

    setState(() {
      _isLoading = false;
    });
  }

  // Store mosque details for the bottom sheet
  void _storeMosqueDetails(List<Marker> mosqueMarkers) {
    _mosqueDetails = mosqueMarkers.map((marker) {
      return {
        'name': marker.infoWindow.title ?? '',
        'distance': marker.infoWindow.snippet ?? '',
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'place_id': marker.markerId.value,
      };
    }).toList();
  }

  // MARK: - Map and UI Interaction Methods

  // Center the map back to the user's current location
  void _centerToUserLocation() {
    if (_currentPosition != null) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  // Display a bottom sheet with nearby mosques
  void _showMosqueBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        // Sort mosques by distance (lowest to highest)
        _mosqueDetails.sort((a, b) => (a['distance'] ?? '').compareTo(b['distance'] ?? ''));

        return Container(
          padding: const EdgeInsets.all(16),
          height: 350, // Adjusted height for better viewing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nearby Mosques',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _mosqueDetails.length,
                  itemBuilder: (context, index) {
                    final mosque = _mosqueDetails[index];
                    return GestureDetector(
                      onTap: () {
                        // Show mosque location when clicked
                        _showMosqueLocation(mosque);
                      },
                      child: Visibility(
                        visible: mosque['name'] != null && mosque['distance'] != null,
                        replacement: const Center(child: CircularProgressIndicator(color: Colors.green)),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(mosque['name']!),
                            subtitle: Text('${mosque['distance']}'),
                            leading: const Icon(Icons.location_on, color: Colors.green),
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
    );
  }

  // Show mosque location on the map when clicked
  void _showMosqueLocation(Map<String, dynamic> mosque) {
    double? lat = mosque['lat'];
    double? lng = mosque['lng'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location data is missing for this mosque.')));
      return;
    }

    final mosqueLocation = LatLng(lat, lng);
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(mosqueLocation, 17));

    _markers.add(Marker(
      markerId: MarkerId(mosque['place_id']),
      position: mosqueLocation,
      infoWindow: InfoWindow(title: mosque['name'], snippet: 'Distance: ${mosque['distance']}'),
    ));

    setState(() {});
  }

  // MARK: - UI Building

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15,
            ),
            onMapCreated: (controller) => _controller = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Search Bar
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: _buildSearchBar(),
          ),

          // Floating Action Button to Center Map
          Positioned(
            bottom: 90,
            right: 20,
            child: _buildCenterLocationButton(),
          ),

          // Bottom Sheet Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildShowMosquesButton(),
          ),
        ],
      ),
    );
  }

  // Build the Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search feature coming soon...',
          prefixIcon: Icon(Icons.search, color: Colors.green),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        onSubmitted: (value) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search feature coming soon!')));
        },
      ),
    );
  }

  // Build the Floating Action Button to Center the Map
  Widget _buildCenterLocationButton() {
    return FloatingActionButton(
      onPressed: _centerToUserLocation,
      backgroundColor: Colors.green,
      child: const Icon(Icons.my_location, color: Colors.white),
    );
  }

  // Build the Elevated Button to Show Nearby Mosques
  Widget _buildShowMosquesButton() {
    return ElevatedButton(
      onPressed: _showMosqueBottomSheet,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text(
        'Show Nearby Mosques',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
