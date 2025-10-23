// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _gpsActive = false;
  String _username = "";
  Stream<Position>? _positionStream;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDriverStats();
    _fetchUserInfo();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.drain();
    super.dispose();
  }

  // ---------------- FETCH USER INFO ----------------
  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString("username");
    setState(() {
      _username = storedUsername ?? "Driver";
    });
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

      setState(() => _gpsActive = true);

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
      setState(() => _gpsActive = false);
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

  // ---------------- CARD BUILDER ----------------
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const Color darwcosGreen = Color(0xFF00695C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(icon, size: 32, color: darwcosGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  // ---------------- MAIN DASHBOARD VIEW ----------------
  Widget _buildDashboardView() {
    const Color darwcosGreen = Color(0xFF00695C);

    return RefreshIndicator(
      onRefresh: _fetchDriverStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🦅 Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Image.asset(
                          "assets/images/black_philippine_eagle.png",
                          height: 60,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, $_username!",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: darwcosGreen,
                            ),
                          ),
                          Text(
                            _gpsActive ? "GPS Active 🛰️" : "GPS Inactive ⚠️",
                            style: TextStyle(
                              color: _gpsActive
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 🔍 Search Bar
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 450,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search...",
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (query) {
                            if (query.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Searching for '$query'...")),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 📊 Driver Stats Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _buildDashboardCard(
                    icon: Icons.local_shipping_rounded,
                    title: "Assigned Pickups",
                    subtitle: _loading
                        ? "Loading..."
                        : "$_activePickups Active",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AssignedPickupsScreen(includeHistory: false),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.history_rounded,
                    title: "Completed Pickups",
                    subtitle: _loading
                        ? "Loading..."
                        : "$_completedPickups Completed",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AssignedPickupsScreen(includeHistory: true),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.map_outlined,
                    title: "Map View",
                    subtitle: "View routes & locations",
                    onTap: () {
                      // TODO: Add map screen navigation
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.settings,
                    title: "Profile & Settings",
                    subtitle: "Manage account",
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "D.A.R.W.C.O.S – Driver Mode",
                  style: TextStyle(
                    color: darwcosGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- DRAWER ----------------
  Drawer _buildAppDrawer() {
    const Color darwcosGreen = Color(0xFF00695C);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: darwcosGreen),
            accountName: Text(
              _username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              _gpsActive ? "GPS: Active" : "GPS: Inactive",
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_shipping, color: darwcosGreen, size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_rounded),
            title: const Text('Assigned Pickups'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AssignedPickupsScreen(includeHistory: false),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Completed Pickups'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AssignedPickupsScreen(includeHistory: true),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: _onLogout,
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------
  @override
  Widget build(BuildContext context) {
    const Color darwcosGreen = Color(0xFF00695C);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _buildAppDrawer(),
      body: _buildDashboardView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: darwcosGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: "Pickups"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
