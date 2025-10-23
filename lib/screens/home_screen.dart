import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'trash_pickup_list_screen.dart';
import 'rewards_dashboard_screen.dart';
import 'employee_list_screen.dart';
import 'my_subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  final String restaurantName;
  final int points;

  const HomeScreen({
    super.key,
    required this.restaurantName,
    required this.points,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  int _pendingPickups = 0;
  int _completedPickups = 0;

  final TextEditingController _searchController = TextEditingController();

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _fetchPickupStats();
  }

  // ---------------- FETCH PICKUP STATS ----------------
  Future<void> _fetchPickupStats() async {
    setState(() => _loading = true);
    try {
      final pickups = await ApiService.getUserPickups();
      final pending = pickups
          .where((p) =>
              p["status"] == "pending" || p["status"] == "in_progress")
          .length;
      final completed =
          pickups.where((p) => p["status"] == "completed").length;
      setState(() {
        _pendingPickups = pending;
        _completedPickups = completed;
      });
    } catch (e) {
      debugPrint("Error fetching pickup stats: $e");
    }
    setState(() => _loading = false);
  }

  // ---------------- CARD BUILDER ----------------
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: darwcosGreen.withOpacity(0.1),
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
    return RefreshIndicator(
      onRefresh: _fetchPickupStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🦅 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/black_philippine_eagle.png",
                        height: 60,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurantName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: darwcosGreen,
                            ),
                          ),
                          Text(
                            "${widget.points} points",
                            style: const TextStyle(
                              color: Colors.black54,
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

              // 📊 Dashboard Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _buildDashboardCard(
                    icon: Icons.delete_outline,
                    title: "Trash Pickups",
                    subtitle: _loading
                        ? "Loading..."
                        : "$_pendingPickups active pickups",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrashPickupListScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.card_giftcard,
                    title: "Rewards",
                    subtitle: "View & redeem your rewards",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RewardsDashboardScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.people,
                    title: "Employees",
                    subtitle: "Manage your staff",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmployeeListScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.subscriptions,
                    title: "Subscription",
                    subtitle: "View your plan & billing",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MySubscriptionScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "D.A.R.W.C.O.S – Restaurant Mode",
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

  // ---------------- MAIN BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _buildDashboardView(),
    );
  }
}
