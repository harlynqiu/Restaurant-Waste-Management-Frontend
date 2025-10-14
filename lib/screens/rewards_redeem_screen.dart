import 'package:flutter/material.dart';

class RewardsRedeemScreen extends StatelessWidget {
  const RewardsRedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of rewards
    final List<Map<String, dynamic>> rewards = [
      {"name": "₱50 Discount Voucher", "points": 50, "icon": Icons.local_offer},
      {"name": "Free Trash Bag", "points": 30, "icon": Icons.shopping_bag},
      {"name": "₱100 Discount Voucher", "points": 100, "icon": Icons.card_giftcard},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Redeem Rewards"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final String name = reward["name"] as String;
          final int points = reward["points"] as int;
          final IconData icon = reward["icon"] as IconData;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Icon(icon, color: Colors.green, size: 28),
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
                                fontWeight: FontWeight.bold,
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
