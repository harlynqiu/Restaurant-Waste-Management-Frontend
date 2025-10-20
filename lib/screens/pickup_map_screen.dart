// lib/screens/pickup_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class PickupMapScreen extends StatefulWidget {
  final double? restaurantLat;
  final double? restaurantLng;
  final int? driverId;

  const PickupMapScreen({
    super.key,
    this.restaurantLat,
    this.restaurantLng,
    this.driverId,
  });

  @override
  State<PickupMapScreen> createState() => _PickupMapScreenState();
}

class _PickupMapScreenState extends State<PickupMapScreen> {
  LatLng? _driverLocation;
  Timer? _timer;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
    // Automatically refresh every few seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchDriverLocation());
  }

  Future<void> _fetchDriverLocation() async {
    if (widget.driverId == null) return;
    try {
      final data = await ApiService.getDriverLocation(widget.driverId!);
      if (!mounted) return;
      setState(() {
        _driverLocation = LatLng(data["latitude"], data["longitude"]);
      });
    } catch (e) {
      print("⚠️ Error fetching driver location: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantPoint = LatLng(
      widget.restaurantLat ?? 7.0731, // fallback (Davao)
      widget.restaurantLng ?? 125.6131,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pickup Map",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: darwcosGreen),
        elevation: 1,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: restaurantPoint,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.darwcos",
          ),
          MarkerLayer(
            markers: [
              // 🏢 Restaurant marker
              Marker(
                point: restaurantPoint,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.store,
                  color: Colors.green,
                  size: 45,
                ),
              ),
              // 🚗 Driver marker
              if (_driverLocation != null)
                Marker(
                  point: _driverLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.blueAccent,
                    size: 45,
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darwcosGreen,
        onPressed: _fetchDriverLocation,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text(
          "Refresh Location",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
