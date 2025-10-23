import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardsRedeemScreen extends StatefulWidget {
  const RewardsRedeemScreen({super.key});

  @override
  State<RewardsRedeemScreen> createState() => _RewardsRedeemScreenState();
}

class _RewardsRedeemScreenState extends State<RewardsRedeemScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  final TextEditingController _searchController = TextEditingController();
  int _points = 0;
  bool _loading = true;

  // Example rewards list
  final List<Map<String, dynamic>> rewards = [
    {"name": "₱50 Discount Voucher", "points": 50, "icon": Icons.local_offer},
    {"name": "Free Trash Bag", "points": 30, "icon": Icons.shopping_bag},
    {"name": "₱100 Discount Voucher", "points": 100, "icon": Icons.card_giftcard},
  ];

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

  // ---------------------- Reward Card ----------------------
  Widget _buildRewardCard({
    required IconData icon,
    required String name,
    required int points,
  }) {
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: darwcosGreen.withOpacity(0.1),
                  child: Icon(icon, color: darwcosGreen, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$points pts",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darwcosGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.redeem, color: Colors.white),
                label: const Text(
                  "Redeem",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Confirm Redemption"),
                      content: Text("Redeem '$name' for $points points?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Confirm"),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    // 🔹 Call backend redeem API
                    await ApiService.redeemReward(
                      rewardName: name,
                      cost: points,
                      rewardType: "voucher", // or "item", depending on your reward
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Successfully redeemed $name!")),
                    );

                    // 🔹 Refresh local points
                    await _fetchPoints();

                    // 🔹 Return to dashboard with success flag
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Redemption failed: $e")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ---------- HEADER ----------
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
                "Redeem Rewards",
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
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                _loading ? "..." : "$_points pts",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------- BODY ----------
      body: RefreshIndicator(
        onRefresh: _fetchPoints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              for (final reward in rewards)
                _buildRewardCard(
                  icon: reward["icon"],
                  name: reward["name"],
                  points: reward["points"],
                ),

              const SizedBox(height: 40),
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
