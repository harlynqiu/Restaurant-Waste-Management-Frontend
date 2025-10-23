import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'my_subscription_screen.dart';

class SubscribePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const SubscribePaymentScreen({super.key, required this.plan});

  @override
  State<SubscribePaymentScreen> createState() => _SubscribePaymentScreenState();
}

class _SubscribePaymentScreenState extends State<SubscribePaymentScreen> {
  String _method = "gcash";
  final TextEditingController _refController = TextEditingController();
  bool _isProcessing = false;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);
    final successPayment = await ApiService.createSubscriptionPayment(
      planId: widget.plan["id"],
      amount: double.parse(widget.plan["price"].toString()),
      method: _method,
      referenceNo: _refController.text.trim(),
    );

    if (successPayment) {
      await ApiService.createSubscription(widget.plan["id"]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Subscription activated successfully!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MySubscriptionScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("❌ Failed to process subscription payment")));
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Subscription"),
        backgroundColor: darwcosGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan["name"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 22, color: darwcosGreen)),
            const SizedBox(height: 8),
            Text(plan["description"] ?? ""),
            const SizedBox(height: 16),
            Text("Price: ₱${plan["price"]} / ${plan["duration_type"]}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 30),

            const Text("Select Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<String>(
              value: _method,
              items: const [
                DropdownMenuItem(value: "gcash", child: Text("GCash")),
                DropdownMenuItem(value: "card", child: Text("Card")),
                DropdownMenuItem(value: "bank_transfer", child: Text("Bank Transfer")),
                DropdownMenuItem(value: "cash", child: Text("Cash")),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: "Reference Number (if applicable)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isProcessing
                ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: darwcosGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _confirmPayment,
                      child: const Text("Confirm Payment",
                          style: TextStyle(color: Colors.white)),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
