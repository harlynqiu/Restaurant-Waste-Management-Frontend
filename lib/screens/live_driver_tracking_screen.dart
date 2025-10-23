import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class LiveDriverTrackingScreen extends StatefulWidget {
  final int driverId;
  final double restaurantLat;
  final double restaurantLng;

  const LiveDriverTrackingScreen({
    super.key,
    required this.driverId,
    required this.restaurantLat,
    required this.restaurantLng,
  });

  @override
  State<LiveDriverTrackingScreen> createState() =>
      _LiveDriverTrackingScreenState();
}

class _LiveDriverTrackingScreenState extends State<LiveDriverTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _previousLocation;
  Timer? _timer;
  AnimationController? _animController;
  Animation<LatLng>? _animation;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
    _timer =
        Timer.periodic(const Duration(seconds: 3), (_) => _fetchDriverLocation());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final data = await ApiService.getDriverLocation(widget.driverId);
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);

        if (_driverLocation == null) {
          setState(() {
            _driverLocation = newLocation;
          });
          _mapController.move(newLocation, 16);
        } else {
          _animateDriverMovement(_driverLocation!, newLocation);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching driver location: $e");
    }
  }

  void _animateDriverMovement(LatLng from, LatLng to) {
    _previousLocation = from;

    _animation = Tween<LatLng>(begin: from, end: to).animate(
      CurvedAnimation(parent: _animController!, curve: Curves.easeInOut),
    );

    _animController!
      ..reset()
      ..forward();

    _animController!.addListener(() {
      setState(() {
        _driverLocation = _animation!.value;
      });
      _mapController.move(_driverLocation!, 16);
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantPoint = LatLng(widget.restaurantLat, widget.restaurantLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Live Tracking"),
        backgroundColor: darwcosGreen,
      ),
      body: _driverLocation == null
          ? const Center(
              child: CircularProgressIndicator(color: darwcosGreen),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: restaurantPoint,
                initialZoom: 14,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.darwcos.app',
                ),

                // ✅ Use MarkerLayer with MarkerLayerWidget for flutter_map 7.x
                MarkerLayer(
                  markers: [
                    // Restaurant marker
                    Marker(
                      point: restaurantPoint,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.store,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    // Animated Driver marker
                    Marker(
                      point: _driverLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.green,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
