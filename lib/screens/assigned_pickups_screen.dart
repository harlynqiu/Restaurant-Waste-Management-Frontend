// lib/screens/assigned_pickups_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'pickup_map_screen.dart';
import 'driver_dashboard.dart';

class AssignedPickupsScreen extends StatefulWidget {
  final bool includeHistory;
  const AssignedPickupsScreen({super.key, this.includeHistory = false});

  @override
  State<AssignedPickupsScreen> createState() => _AssignedPickupsScreenState();
}

class _AssignedPickupsScreenState extends State<AssignedPickupsScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  bool _loading = true;
  List<dynamic> _pickups = [];

  @override
  void initState() {
    super.initState();
    _fetchPickups();
  }

  Future<void> _fetchPickups() async {
    setState(() => _loading = true);
    try {
      final data =
          await ApiService.getDriverPickups(includeHistory: widget.includeHistory);
      setState(() => _pickups = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load pickups: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptPickup(Map<String, dynamic> pickup) async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.startPickup(pickup["id"]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup accepted")),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PickupMapScreen(
            restaurantLat: pickup["restaurant_latitude"] ?? 0.0,
            restaurantLng: pickup["restaurant_longitude"] ?? 0.0,
            driverId: pickup["driver_id"] ?? (pickup["driver"]?["id"]) ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completePickup(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Completion"),
        content: const Text("Are you sure you want to mark this pickup as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
            child: const Text("Yes, Complete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.completePickup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result["message"] ?? "Done")));
      _fetchPickups();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  String _formatDateTime(String? s) {
    if (s == null || s.isEmpty) return "";
    try {
      final dt = DateTime.parse(s);
      return DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
    } catch (_) {
      return s;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "COMPLETED":
        return Colors.blueGrey;
      case "IN_PROGRESS":
        return Colors.orange;
      default:
        return darwcosGreen;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case "COMPLETED":
        return Icons.check_circle_outline;
      case "IN_PROGRESS":
        return Icons.timelapse_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
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
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darwcosGreen),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
            );
          },
        ),
        title: Text(
          widget.includeHistory ? "Completed Pickups" : "Assigned Pickups",
          style: const TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPickups,
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 📦 Pickups list
            Expanded(
              child: _pickups.isEmpty
                  ? const Center(
                      child: Text(
                        "No pickups found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: _pickups.length,
                      itemBuilder: (context, index) {
                        final p = _pickups[index];
                        final status = (p["status"] ?? "").toString();
                        final statusColor = _statusColor(status);
                        final icon = _statusIcon(status);
                        final address = p["address"] ?? "Unknown address";
                        final waste = p["waste_type_display"] ??
                            p["waste_type"] ??
                            "N/A";
                        final weight = p["trash_weight"] ?? "N/A";
                        final schedule = _formatDateTime(p["scheduled_date"]);

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 🚚 Icon
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      Icon(icon, color: statusColor, size: 28),
                                ),
                                const SizedBox(width: 16),

                                // 📦 Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Waste: $waste • $weight kg",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "📅 $schedule",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🎯 Status & Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!widget.includeHistory)
                                      if (status == "pending")
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: darwcosGreen,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.white, size: 18),
                                          label: const Text(
                                            "Accept",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          onPressed: () => _acceptPickup(p),
                                        )
                                      else if (status == "in_progress")
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: const Icon(Icons.flag,
                                              color: Colors.white, size: 18),
                                          label: const Text(
                                            "Complete",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          onPressed: () =>
                                              _completePickup(p["id"]),
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
