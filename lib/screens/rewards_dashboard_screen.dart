import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  int _points = 0;
  bool _loading = true;
  bool _loadingMyRewards = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isGlowing = false;

  String _currentBadge = "First Trash Hero";
  String _nextBadge = "Bronze Collector";
  double _progress = 0.0;
  int _pointsToNext = 0;

  List<Map<String, dynamic>> _myRewards = [];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation =
        Tween<double>(begin: 0.0, end: 15.0).animate(_glowController);
    _fetchPoints();
    _fetchMyRewards();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchPoints() async {
    setState(() => _loading = true);
    final newPoints = await ApiService.getUserPoints();
    if (!mounted) return;

    if (newPoints > _points && !_isGlowing) _startGlowEffect();
    _updateBadgeProgress(newPoints);

    setState(() {
      _points = newPoints;
      _loading = false;
    });
  }

  Future<void> _fetchMyRewards() async {
    setState(() => _loadingMyRewards = true);
    try {
      final data = await ApiService.getMyRewards();
      if (!mounted) return;
      setState(() {
        _myRewards = List<Map<String, dynamic>>.from(data ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load rewards: $e")));
    } finally {
      setState(() => _loadingMyRewards = false);
    }
  }

  void _startGlowEffect() async {
    setState(() => _isGlowing = true);
    await _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 4));
    await _glowController.reverse();
    _glowController.stop();
    setState(() => _isGlowing = false);
  }

  void _updateBadgeProgress(int pts) {
    int previous = 0;
    int next = 100;
    String current = "First Trash Hero";
    String upcoming = "Bronze Collector";

    if (pts >= 100 && pts < 250) {
      previous = 100;
      next = 250;
      current = "Bronze Collector";
      upcoming = "Silver Recycler";
    } else if (pts >= 250 && pts < 500) {
      previous = 250;
      next = 500;
      current = "Silver Recycler";
      upcoming = "Gold Waste Warrior";
    } else if (pts >= 500) {
      previous = 500;
      next = 1000;
      current = "Gold Waste Warrior";
      upcoming = "Eco Legend 🌎";
    }

    final progress =
        ((pts - previous) / (next - previous)).clamp(0.0, 1.0).toDouble();
    final remaining = (next - pts).clamp(0, next);

    setState(() {
      _currentBadge = current;
      _nextBadge = upcoming;
      _progress = progress;
      _pointsToNext = remaining;
    });
  }

  Future<void> _redeemReward(String name, int cost, bool isVoucher) async {
    if (_points < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Not enough points to redeem this reward."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Redemption"),
        content: Text("Redeem '$name' for $cost points?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.redeemReward(
        rewardName: name,
        cost: cost,
        rewardType: isVoucher ? "voucher" : "item",
      );

      if (result != null && result["success"] == true) {
        setState(() {
          _points = result["remaining_points"] ?? _points;
        });
        _showResultDialog(
          title: isVoucher ? "🎉 Voucher Redeemed!" : "📦 Item Redeemed!",
          message: result["message"] ?? "You’ve redeemed '$name'!",
        );
        _fetchMyRewards();
        _updateBadgeProgress(_points);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?["detail"] ?? "Redemption failed.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showResultDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: darwcosGreen)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required String name,
    required String image,
    required int points,
    required bool isVoucher,
  }) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  Image.asset(image, height: 60, width: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text("$points pts",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _redeemReward(name, points, isVoucher),
              child: const Text("Redeem",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRewardCard(Map<String, dynamic> reward) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: darwcosGreen),
        title: Text(reward["reward_name"] ?? "Unknown"),
        subtitle: Text(
            "Type: ${reward["reward_type"] ?? "unknown"} • Status: ${reward["status"] ?? "completed"}"),
        trailing: Text(
          "${reward["points"] ?? 0} pts",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: darwcosGreen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rewards = [
      {
        "name": "₱50 Discount Voucher",
        "points": 50,
        "image": "assets/images/50_discount.png",
        "isVoucher": true,
      },
      {
        "name": "Free Trash Bag",
        "points": 30,
        "image": "assets/images/trashbag.png",
        "isVoucher": false,
      },
      {
        "name": "₱100 Discount Voucher",
        "points": 100,
        "image": "assets/images/100_discount.png",
        "isVoucher": true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: true,
        title: const Text(
          "Rewards",
          style: TextStyle(
            color: darwcosGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: darwcosGreen),
      ),
      body: Stack(
        children: [
          Container(height: 180, width: double.infinity, color: darwcosGreen),
          RefreshIndicator(
            onRefresh: () async {
              await _fetchPoints();
              await _fetchMyRewards();
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildPointsAndBadgeSection(),
                const SizedBox(height: 30),
                const Text(
                  "Redeem Rewards",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ...rewards.map((r) => _buildRewardCard(
                      name: r["name"]!,
                      image: r["image"]!,
                      points: r["points"]!,
                      isVoucher: r["isVoucher"]!,
                    )),
                const SizedBox(height: 30),
                const Text(
                  "My Rewards",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingMyRewards)
                  const Center(child: CircularProgressIndicator())
                else if (_myRewards.isEmpty)
                  const Center(
                      child: Text("You haven’t redeemed any rewards yet."))
                else
                  ..._myRewards.map((r) => _buildMyRewardCard(r)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAndBadgeSection() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "My Points",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darwcosGreen,
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchPoints,
                          icon: const Icon(Icons.refresh, color: darwcosGreen),
                        ),
                      ],
                    ),
                    Text(
                      _loading ? "..." : "$_points pts",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[200],
                      color: darwcosGreen,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _points >= 1000
                          ? "🏆 Max badge achieved!"
                          : "$_pointsToNext pts to $_nextBadge",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: _isGlowing
                        ? [
                            BoxShadow(
                              color: darwcosGreen.withOpacity(0.4),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 3,
                            ),
                          ]
                        : [],
                  ),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/first_trash_badge.png",
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentBadge,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Next: $_nextBadge",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
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
  }
}
