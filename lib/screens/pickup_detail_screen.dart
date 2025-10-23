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
  bool _loadingVouchers = false;
  List<dynamic> _availableVouchers = [];

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

  Future<void> _refreshPickup() async {
    try {
      final refreshed = await ApiService.getPickupDetail(p["id"]);
      setState(() => p = refreshed);
    } catch (_) {
      // ignore for now
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

  // 🔹 Load vouchers the user has redeemed but not yet used
  Future<void> _loadAvailableVouchers() async {
    setState(() => _loadingVouchers = true);
    try {
      final vouchers = await ApiService.getAvailableVouchers();
      setState(() => _availableVouchers = vouchers);
      _showVoucherDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load vouchers: $e")),
      );
    }
    setState(() => _loadingVouchers = false);
  }

  // 🔹 Show list of vouchers to pick from
  void _showVoucherDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (_availableVouchers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text("No available vouchers found.")),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select a Voucher to Apply",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darwcosGreen,
                ),
              ),
              const SizedBox(height: 12),
              ..._availableVouchers.map((v) {
                final code = v["code"] ?? "Unnamed Voucher";
                final discount = v["discount_amount"] ?? 0;
                return ListTile(
                  leading: const Icon(Icons.local_offer_outlined,
                      color: darwcosGreen),
                  title: Text(code),
                  subtitle: Text("Discount: ₱$discount"),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmApplyVoucher(v);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Ask user to confirm applying voucher
  void _confirmApplyVoucher(Map<String, dynamic> voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Apply Voucher"),
        content: Text(
            "Apply voucher ${voucher["code"]} (₱${voucher["discount_amount"]}) to this pickup?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
            onPressed: () {
              Navigator.pop(context);
              _applyVoucher(voucher);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  // 🔹 Actually apply selected voucher to pickup
  Future<void> _applyVoucher(Map<String, dynamic> voucher) async {
    setState(() => _busy = true);
    try {
      final response =
          await ApiService.applyVoucherToPickup(p["id"], voucher["id"]);
      setState(() => p = response);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Voucher ${voucher["code"]} applied successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to apply voucher: $e")),
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

    final baseAmount = p["base_amount"] ?? 0;
    final totalAmount = p["total_amount"] ?? baseAmount;
    final discount = (p["voucher_discount"] ?? 0).toString();

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
        onRefresh: _refreshPickup,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🟩 Header
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

              // 🌿 Info cards
              _buildInfoCard(
                  icon: Icons.info_outline,
                  title: "Status",
                  value: status.toUpperCase(),
                  color: color),
              _buildInfoCard(
                  icon: Icons.scale,
                  title: "Estimated Weight",
                  value: "${p["trash_weight"]} kg"),
              _buildInfoCard(
                  icon: Icons.delete_outline,
                  title: "Waste Type",
                  value: p["waste_type_display"] ?? ""),
              _buildInfoCard(
                  icon: Icons.person_outline,
                  title: "Driver",
                  value: p["driver_username"] ?? "Unassigned"),

              // 💰 Billing section
              _buildInfoCard(
                icon: Icons.payments_outlined,
                title: "Base Amount",
                value: "₱$baseAmount",
                color: darwcosGreen,
              ),

              if (p["voucher_code"] != null)
                _buildInfoCard(
                  icon: Icons.local_offer_outlined,
                  title: "Voucher Applied",
                  value: "${p["voucher_code"]} (-₱$discount)",
                  color: Colors.purple,
                ),

              _buildInfoCard(
                icon: Icons.attach_money,
                title: "Total Amount",
                value: "₱$totalAmount",
                color: Colors.teal,
              ),

              const SizedBox(height: 15),

              // 🎟️ Apply Voucher Button
              if (status == "pending" && p["voucher_code"] == null)
                (_loadingVouchers)
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: darwcosGreen),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text("Apply Voucher"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darwcosGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _loadAvailableVouchers,
                      ),

              const SizedBox(height: 25),

              // ❌ Cancel Pickup
              if (!_busy &&
                  status != "completed" &&
                  status != "cancelled")
                OutlinedButton.icon(
                  onPressed: _doCancel,
                  icon: const Icon(Icons.close),
                  label: const Text("Cancel Pickup"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
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

  // 🌱 Info Card Builder
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
