import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'subscription_plans_screen.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  Map<String, dynamic>? _subscription;
  bool _isLoading = true;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final data = await ApiService.getMySubscription();
      if (!mounted) return;
      setState(() {
        _subscription = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "My Subscription",
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
              onRefresh: _loadSubscription,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    // 🟩 Active subscription card
                    _subscription == null
                        ? Column(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.grey, size: 60),
                              const SizedBox(height: 16),
                              const Text(
                                "No active subscription found.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SubscriptionPlansScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.white),
                                label: const Text(
                                  "View Available Plans",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _subscription!["plan_details"]?["name"] ??
                                              "Unnamed Plan",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: darwcosGreen,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: darwcosGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _subscription!["status"]?.toUpperCase() ??
                                              "ACTIVE",
                                          style: const TextStyle(
                                            color: darwcosGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _subscription!["plan_details"]?["description"] ??
                                        "Subscription plan details not available.",
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
                                        "Start Date:",
                                        style: TextStyle(
                                            color: Colors.black54, fontSize: 14),
                                      ),
                                      Text(
                                        _subscription!["start_date"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "End Date:",
                                        style: TextStyle(
                                            color: Colors.black54, fontSize: 14),
                                      ),
                                      Text(
                                        _subscription!["end_date"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.upgrade_rounded,
                                            color: darwcosGreen),
                                        label: const Text(
                                          "Upgrade Plan",
                                          style: TextStyle(
                                            color: darwcosGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SubscriptionPlansScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                    // 💡 Footer branding
                    const SizedBox(height: 30),
                    const Text(
                      "D.A.R.W.C.O.S",
                      style: TextStyle(
                        color: darwcosGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
