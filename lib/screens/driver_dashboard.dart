// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'assigned_pickups_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'available_pickups_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _activePickups = 0;
  int _completedPickups = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverStats();
  }

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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(icon, size: 32, color: Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchDriverStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome + Logout row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Welcome, Driver",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      tooltip: "Logout",
                      onPressed: _onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Dashboard grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.local_shipping,
                      title: "Active Pickups",
                      subtitle: _loading
                          ? "Loading..."
                          : "$_activePickups ongoing",
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignedPickupsScreen(includeHistory: false),
                          ),
                        );
                        if (updated == true) {
                          _fetchDriverStats(); // ✅ refresh stats
                        }
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.check_circle,
                      title: "Completed Pickups",
                      subtitle: _loading
                          ? "Loading..."
                          : "$_completedPickups done",
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignedPickupsScreen(includeHistory: true),
                          ),
                        );
                        if (updated == true) {
                          _fetchDriverStats(); // ✅ refresh stats
                        }
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.list_alt,
                      title: "Available Pickups",
                      subtitle: "Claim new requests",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AvailablePickupsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.person,
                      title: "Profile",
                      subtitle: "Update your info",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer brand
                const Center(
                  child: Text(
                    "🦅 DARWCOS DRIVER",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
