// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'trash_pickup_list_screen.dart';
import 'rewards_dashboard_screen.dart';
import 'rewards_history_screen.dart';
import 'employee_list_screen.dart';
import 'pickup_map_screen.dart'; // ✅ NEW IMPORT
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _points = 0;
  bool _loadingPoints = true;
  String _username = "";
  String _restaurantName = "";
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    await Future.wait([
      _fetchPoints(),
      _fetchUserInfo(),
    ]);
  }

  Future<void> _fetchPoints() async {
    final pts = await ApiService.getUserPoints();
    if (!mounted) return;
    setState(() {
      _points = pts;
      _loadingPoints = false;
    });
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRestaurant = prefs.getString("restaurant_name");
    final storedUsername = prefs.getString("username");

    if (storedRestaurant != null) {
      setState(() {
        _restaurantName = storedRestaurant;
        _username = storedUsername ?? "User";
      });
      return;
    }

    final user = await ApiService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _username = user?["username"] ?? "User";
      _restaurantName = user?["restaurant_name"] ?? "Your Restaurant";
    });
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

  // ---------- Dashboard View ----------
  Widget _buildDashboardView() {
    const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Logo + Restaurant (left), Search (center), Points (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🦅 Logo + Restaurant Name
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Image.asset(
                          "assets/images/black_philippine_eagle.png",
                          height: 60,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _restaurantName.isNotEmpty
                            ? "Welcome, $_restaurantName!"
                            : "Welcome, $_username!",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: darwcosGreen,
                        ),
                      ),
                    ],
                  ),

                  // 🔍 Centered Search Bar
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
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

                  // 💰 Points Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: darwcosGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _loadingPoints ? "..." : "$_points pts",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ✅ Dashboard Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _buildDashboardCard(
                    icon: Icons.schedule,
                    title: "Schedule a Pick-Up",
                    subtitle: "Book date & time",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrashPickupListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.receipt_long,
                    title: "Past Transactions",
                    subtitle: "Your history of points",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RewardsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.card_giftcard,
                    title: "Rewards",
                    subtitle: "Redeem your points",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RewardsDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.people,
                    title: "Employees",
                    subtitle: "Manage staff",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeListScreen(),
                        ),
                      );
                    },
                  ),
                  // ✅ NEW MAP CARD
                  _buildDashboardCard(
                    icon: Icons.map_outlined,
                    title: "Pickup Map",
                    subtitle: "View pickup locations",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PickupMapScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Center(
                child: Text(
                  "D.A.R.W.C.O.S",
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
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

  // ---------- Drawer ----------
  Drawer _buildAppDrawer() {
    const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: darwcosGreen),
            accountName: Text(
              _restaurantName.isEmpty ? "Your Restaurant" : _restaurantName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("$_points points"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.restaurant, color: darwcosGreen, size: 36),
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
            leading: const Icon(Icons.schedule),
            title: const Text('Trash Pickups'),
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Rewards'),
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Employees'),
            onTap: () {
              setState(() => _selectedIndex = 3);
              Navigator.pop(context);
            },
          ),
          // ✅ ADD MAP LINK
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Pickup Map'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PickupMapScreen()),
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

  // ---------- Bottom Navigation ----------
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const TrashPickupListScreen();
      case 2:
        return const RewardsDashboardScreen();
      case 3:
        return const EmployeeListScreen();
      default:
        return _buildDashboardView();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _buildAppDrawer(),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: darwcosGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Pickups"),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Rewards"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Employees"),
        ],
      ),
    );
  }
}
