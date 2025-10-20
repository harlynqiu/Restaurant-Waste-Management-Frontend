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

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isGlowing = false;

  String _currentBadge = "First Trash Hero";
  String _nextBadge = "Bronze Collector";
  double _progress = 0.0;
  int _pointsToNext = 0;

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

    if (newPoints > _points && !_isGlowing) {
      _startGlowEffect();
    }

    _updateBadgeProgress(newPoints);

    setState(() {
      _points = newPoints;
      _loading = false;
    });
  }

  void _startGlowEffect() async {
    setState(() => _isGlowing = true);
    await _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 4));
    await _glowController.reverse();
    _glowController.stop();
    setState(() => _isGlowing = false);
  }

  // ---------- 🏅 Determine badge tier based on points ----------
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

  // ---------- Reward Card ----------
  Widget _buildRewardCard({
    required String name,
    required String image,
    required int points,
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
              child: Image.asset(
                image,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$points pts",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Redeemed $name")),
                );
              },
              child: const Text(
                "Redeem",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Badge Card ----------
  Widget _buildBadgeCard() {
    return AnimatedBuilder(
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
          child: SizedBox(
            height: 190,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: darwcosGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/first_trash_badge.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Current Badge: ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darwcosGreen,
                                ),
                              ),
                              Text(
                                _currentBadge,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Next: $_nextBadge",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("See more badges soon!"),
                                ),
                              );
                            },
                            child: const Text(
                              "see more →",
                              style: TextStyle(
                                color: darwcosGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final rewards = [
      {
        "name": "₱50 Discount Voucher",
        "points": 50,
        "image": "assets/images/50_discount.png",
      },
      {
        "name": "Free Trash Bag",
        "points": 30,
        "image": "assets/images/trashbag.png",
      },
      {
        "name": "₱100 Discount Voucher",
        "points": 100,
        "image": "assets/images/100_discount.png",
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 🟩 My Points + 🏅 Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Points Card
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      icon: const Icon(Icons.refresh,
                                          color: darwcosGreen),
                                    ),
                                  ],
                                ),
                                Text(
                                  _loading
                                      ? "..."
                                      : "${_points.toStringAsFixed(1)} pts",
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
                      Expanded(flex: 1, child: _buildBadgeCard()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🎁 Rewards Section
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Redeem Rewards",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darwcosGreen,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: rewards.map((reward) {
                          return SizedBox(
                            width: 320,
                            child: _buildRewardCard(
                              name: reward["name"] as String,
                              image: reward["image"] as String,
                              points: reward["points"] as int,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
