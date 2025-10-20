import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'rewards_redeem_screen.dart';

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen> {
  int _points = 0;
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _fetchPoints();
  }

  Future<void> _fetchPoints() async {
    setState(() => _loading = true);
    final pts = await ApiService.getUserPoints();
    if (!mounted) return;
    setState(() {
      _points = pts;
      _loading = false;
    });
  }

  // ---------------- Reward Card ----------------
  Widget _buildRewardCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Points Card ----------------
  Widget _buildPointsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Your Points",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darwcosGreen,
              ),
            ),
            _loading
                ? const CircularProgressIndicator(color: darwcosGreen)
                : Text(
                    "$_points pts",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darwcosGreen,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------- Main UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: true,
          titleSpacing: 0,
          title: Row(
            children: [
              const Text(
                "Rewards",
                style: TextStyle(
                  color: darwcosGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search rewards...",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: darwcosGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$_points pts",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------------- BODY ----------------
      body: RefreshIndicator(
        onRefresh: _fetchPoints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildPointsCard(),
              const SizedBox(height: 24),
              _buildRewardCard(
                icon: Icons.card_giftcard,
                iconColor: Colors.blue,
                title: "Redeem Rewards",
                subtitle: "Use your points to claim exciting offers.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RewardsRedeemScreen(),
                    ),
                  );
                },
              ),
              _buildRewardCard(
                icon: Icons.history,
                iconColor: Colors.orange,
                title: "View History",
                subtitle: "Check your previous reward activities.",
                onTap: () {
                  // You can link your rewards history screen here
                },
              ),
              const SizedBox(height: 50),
              Image.asset(
                "assets/images/black_philippine_eagle.png",
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
