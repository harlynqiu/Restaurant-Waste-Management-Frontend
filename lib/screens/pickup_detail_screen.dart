import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PickupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;
  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  late Map<String, dynamic> p;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    p = Map<String, dynamic>.from(widget.pickup);
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return "—";
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _doCancel() async {
    setState(() => _busy = true);
    try {
      final updated = await ApiService.cancelPickup(p["id"]);
      setState(() => p = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup cancelled.")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel: $e")),
      );
    }
    setState(() => _busy = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orangeAccent;
      case "in_progress":
        return Colors.blueAccent;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "completed":
        return Icons.check_circle_outline;
      case "cancelled":
        return Icons.cancel_outlined;
      case "in_progress":
        return Icons.play_circle_outline;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (p["status"] ?? "unknown").toString();
    final color = _statusColor(status);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Pickup Details",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => p = widget.pickup);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🟩 Header Card
              Card(
                elevation: 6,
                shadowColor: darwcosGreen.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Row(
                    children: [
                      // Icon with background
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(_statusIcon(status), color: color, size: 34),
                      ),
                      const SizedBox(width: 18),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["address"] ?? "No address provided",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDateTime(p["scheduled_date"]),
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
                ),
              ),

              const SizedBox(height: 20),

              // 🌿 Detail Cards
              _buildInfoCard(
                icon: Icons.info_outline,
                title: "Status",
                value: status.toUpperCase(),
                color: color,
              ),
              if (p["trash_weight"] != null)
                _buildInfoCard(
                  icon: Icons.scale,
                  title: "Estimated Weight",
                  value: "${p["trash_weight"]} kg",
                ),
              if (p["waste_type_display"] != null)
                _buildInfoCard(
                  icon: Icons.delete_outline,
                  title: "Waste Type",
                  value: p["waste_type_display"],
                ),
              if (p["driver_username"] != null)
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: "Assigned Driver",
                  value: p["driver_username"] ?? "Unassigned",
                ),

              const SizedBox(height: 25),

              // 🔴 Cancel Button Section (only if not completed)
              if (!_busy &&
                  status != "completed" &&
                  status != "cancelled")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    elevation: 5,
                    shadowColor: Colors.redAccent.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _doCancel,
                          icon: const Icon(Icons.close),
                          label: const Text("Cancel Pickup"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                                color: Colors.redAccent, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: darwcosGreen),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌱 Helper widget for consistent card design
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color color = darwcosGreen,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
