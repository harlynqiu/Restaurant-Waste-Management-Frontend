import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'trash_pickup_form_screen.dart';
import 'pickup_detail_screen.dart';

class TrashPickupListScreen extends StatefulWidget {
  const TrashPickupListScreen({super.key});

  @override
  State<TrashPickupListScreen> createState() => _TrashPickupListScreenState();
}

class _TrashPickupListScreenState extends State<TrashPickupListScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  List<dynamic> pickups = [];
  bool _isLoading = true;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final pts = await ApiService.getUserPoints();
      final list = await ApiService.getTrashPickupsAuto();
      setState(() {
        _points = pts;
        pickups = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openDetail(Map<String, dynamic> pickup) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupDetailScreen(pickup: pickup),
      ),
    );
    if (updated == true) _fetchAll();
  }

  void _addPickup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrashPickupFormScreen(),
      ),
    );
    if (created == true) _fetchAll();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.orangeAccent;
      case "IN_PROGRESS":
        return Colors.blueAccent;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Icons.schedule;
      case "IN_PROGRESS":
        return Icons.play_circle_outline;
      case "COMPLETED":
        return Icons.check_circle_outline;
      case "CANCELLED":
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Trash Pickups",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Chip(
              label: Text(
                "$_points pts",
                style: const TextStyle(
                  color: darwcosGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: darwcosGreen.withOpacity(0.1),
              side: const BorderSide(color: darwcosGreen),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPickup,
        backgroundColor: darwcosGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Pickup",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: darwcosGreen),
            )
          : pickups.isEmpty
              ? const Center(
                  child: Text(
                    "No pickups yet.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAll,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: pickups.length,
                    itemBuilder: (context, i) {
                      final p = pickups[i];
                      final status =
                          p["status"]?.toString().toUpperCase() ?? "UNKNOWN";
                      final color = _getStatusColor(status);
                      final icon = _getStatusIcon(status);

                      return Card(
                        elevation: 4,
                        shadowColor: darwcosGreen.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openDetail(p),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Status Icon
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 28),
                                ),
                                const SizedBox(width: 14),

                                // Address and date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p["address"] ?? "No address provided",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy • hh:mm a')
                                            .format(
                                          DateTime.parse(
                                              p["scheduled_date"].toString()),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
