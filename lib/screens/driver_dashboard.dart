// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'assigned_pickups_screen.dart';
import 'login_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _activePickups = 0;
  int _completedPickups = 0;
  bool _loading = true;
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _fetchDriverStats();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.drain();
    super.dispose();
  }

  // ---------------- GPS LIVE TRACKING ----------------
  Future<void> _startLiveTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _positionStream!.listen((Position position) async {
        await ApiService.updateDriverLocation(
          position.latitude,
          position.longitude,
        );
      });
    } catch (e) {
      debugPrint("GPS tracking error: $e");
    }
  }

  // ---------------- FETCH PICKUP STATS ----------------
  Future<void> _fetchDriverStats() async {
    setState(() => _loading = true);
    try {
      final pickups = await ApiService.getDriverPickups(includeHistory: true);
      final active = pickups
          .where((p) => p["status"] == "pending" || p["status"] == "in_progress")
          .length;
      final completed = pickups.where((p) => p["status"] == "completed").length;
      setState(() {
        _activePickups = active;
        _completedPickups = completed;
      });
    } catch (e) {
      debugPrint("Failed to fetch driver stats: $e");
    }
    setState(() => _loading = false);
  }

  // ---------------- LOGOUT ----------------
  void _onLogout() async {
    final success = await ApiService.logout();
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed. Try again.")),
      );
    }
  }

  // ---------------- CARD WIDGET ----------------
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? startColor,
    Color? endColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor ?? Colors.green, endColor ?? Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 38),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _fetchDriverStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // -------- HEADER --------
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Driver Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.white, size: 28),
                          tooltip: "Logout",
                          onPressed: _onLogout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Stay on track and manage your pickups",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // -------- DASHBOARD STATS --------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                  children: [
                    _buildStatCard(
                      icon: Icons.local_shipping_outlined,
                      title: "Current Pickups",
                      subtitle:
                          _loading ? "Loading..." : "$_activePickups ongoing",
                      startColor: Colors.green.shade700,
                      endColor: Colors.teal.shade600,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignedPickupsScreen(includeHistory: false),
                          ),
                        );
                        if (updated == true) _fetchDriverStats();
                      },
                    ),
                    _buildStatCard(
                      icon: Icons.history_rounded,
                      title: "Past Transactions",
                      subtitle:
                          _loading ? "Loading..." : "$_completedPickups completed",
                      startColor: Colors.indigo.shade700,
                      endColor: Colors.blue.shade600,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignedPickupsScreen(includeHistory: true),
                          ),
                        );
                        if (updated == true) _fetchDriverStats();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // -------- FOOTER --------
              const Text(
                "🛻 DRIVER MODE ACTIVE",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
