// lib/screens/subscription_plans_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'my_subscription_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = true;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  static const Color lightGreen = Color.fromARGB(255, 220, 243, 220);
  static const Color gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final data = await ApiService.getSubscriptionPlans();
      if (!mounted) return;
      setState(() {
        _plans = data
            .where((plan) =>
                plan["name"] == "Basic Plan" ||
                plan["name"] == "Standard Plan" ||
                plan["name"] == "Premium Plan")
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load plans: $e")),
      );
    }
  }

  Future<void> _subscribe(int planId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Processing subscription...")),
    );

    final success = await ApiService.createSubscription(planId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Subscription successful!"),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MySubscriptionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Subscription failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildBadge(String planName) {
    if (planName == "Standard Plan") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: darwcosGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "💚 Most Popular",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (planName == "Premium Plan") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "🏆 Best Value",
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Available Plans",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: darwcosGreen),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : RefreshIndicator(
              color: darwcosGreen,
              onRefresh: _fetchPlans,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                itemCount: _plans.length,
                itemBuilder: (context, i) {
                  final plan = _plans[i];
                  final planName = plan["name"] ?? "Unnamed Plan";
                  final planDescription =
                      plan["description"] ?? "No description provided.";
                  final planPrice = plan["price"] ?? 0;
                  final planDuration = plan["duration_type"] ?? "month";
                  final isPopular = planName == "Standard Plan";
                  final isPremium = planName == "Premium Plan";

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.only(bottom: 20),
                    color: isPopular ? lightGreen : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  planName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: darwcosGreen,
                                  ),
                                ),
                              ),
                              _buildBadge(planName),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            planDescription,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Price:",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "₱$planPrice / $planDuration",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _subscribe(plan["id"]),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                              label: const Text(
                                "Subscribe Now",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
