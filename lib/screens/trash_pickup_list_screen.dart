import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'trash_pickup_form_screen.dart';
import 'map_screen.dart'; // ✅ Import MapScreen

class TrashPickupListScreen extends StatefulWidget {
  const TrashPickupListScreen({super.key});

  @override
  State<TrashPickupListScreen> createState() => _TrashPickupListScreenState();
}

class _TrashPickupListScreenState extends State<TrashPickupListScreen> {
  List<dynamic> pickups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPickups();
  }

  Future<void> _fetchPickups() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getTrashPickups();
      setState(() {
        pickups = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load trash pickups: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deletePickup(int id) async {
    final success = await ApiService.deleteTrashPickup(id);
    if (success) {
      _fetchPickups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup deleted")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete pickup")),
      );
    }
  }

  Future<void> _cancelPickup(int id) async {
    try {
      final result = await ApiService.cancelPickup(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup cancelled")),
      );
      _fetchPickups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel pickup: $e")),
      );
    }
  }

  Widget _buildPickupCard(Map<String, dynamic> pickup) {
    DateTime? scheduledDateTime;
    try {
      scheduledDateTime = DateTime.parse(pickup['scheduled_date']);
    } catch (_) {
      scheduledDateTime = null;
    }

    final dateString = scheduledDateTime != null
        ? DateFormat('yyyy-MM-dd').format(scheduledDateTime)
        : pickup['scheduled_date'];

    final timeString = scheduledDateTime != null
        ? DateFormat('HH:mm').format(scheduledDateTime)
        : "";

    final status = pickup['status'];
    final driver = pickup['driver_username'] ?? "Unassigned";

    // ✅ Prefer the display label, fallback to raw value
    final wasteType = pickup['waste_type_display'] ??
        pickup['waste_type'] ??
        "Not specified";

    Color statusColor;
    switch (status) {
      case "completed":
        statusColor = Colors.green;
        break;
      case "cancelled":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address + Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pickup['address'] ?? "No address",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Details
            Text("Date: $dateString"),
            if (timeString.isNotEmpty) Text("Time: $timeString"),
            Text("Waste Type: $wasteType"),
            Text("Weight: ${pickup['trash_weight']} kg"),
            Text("Driver: $driver"),

            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ New "View on Map" button
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.green),
                  tooltip: "View on Map",
                  onPressed: () {
                    if (pickup['latitude'] != null && pickup['longitude'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(
                            latitude: pickup['latitude'],
                            longitude: pickup['longitude'],
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No coordinates available for this pickup.")),
                      );
                    }
                  },
                ),

                if (status != 'cancelled' && status != 'completed') ...[
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.orange),
                    tooltip: "Cancel",
                    onPressed: () => _cancelPickup(pickup['id']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: "Edit",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrashPickupFormScreen(pickup: pickup),
                        ),
                      ).then((_) => _fetchPickups());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Delete",
                    onPressed: () => _deletePickup(pickup['id']),
                  ),
                ] else
                  const Text(
                    "No actions available",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Trash Pickups"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPickups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pickups.isEmpty
              ? const Center(
                  child: Text(
                    "No pickups scheduled",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPickups,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: pickups.length,
                    itemBuilder: (context, index) {
                      return _buildPickupCard(pickups[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("New Pickup"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TrashPickupFormScreen(),
            ),
          ).then((_) => _fetchPickups());
        },
      ),
    );
  }
}
