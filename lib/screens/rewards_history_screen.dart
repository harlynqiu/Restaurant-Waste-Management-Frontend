import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RewardsHistoryScreen extends StatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  State<RewardsHistoryScreen> createState() => _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen> {
  int? _points;
  bool _loading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    try {
      final pts = await ApiService.getUserPoints();
      final txs = await ApiService.getUserTransactions();
      setState(() {
        _points = pts;
        _transactions = txs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load rewards: $e")),
      );
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "";
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat("yyyy-MM-dd hh:mm a").format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  Color _statusColor(String status, int pts) {
    if (status == "cancelled") return Colors.grey;
    return pts > 0 ? Colors.green : Colors.red;
  }

  String _statusLabel(String status, int pts) {
    if (status == "cancelled") return "Cancelled";
    return pts > 0 ? "Earned" : "Redeemed";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRewards,
        child: Column(
          children: [
            // Total points badge
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Total Points: ${_points ?? 0}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text(
                        "No reward history found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final pts = tx['points'] ?? 0;
                        final desc = tx['description'] ?? "Transaction";
                        final status = tx['status'] ?? "completed";
                        final createdAt = _formatDateTime(tx['created_at']);

                        final color = _statusColor(status, pts);
                        final label = _statusLabel(status, pts);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: description + points
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${pts > 0 ? '+' : ''}$pts pts",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Date + status badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "📅 $createdAt",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
