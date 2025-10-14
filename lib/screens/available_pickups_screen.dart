// lib/screens/available_pickups_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AvailablePickupsScreen extends StatefulWidget {
  const AvailablePickupsScreen({super.key});

  @override
  State<AvailablePickupsScreen> createState() => _AvailablePickupsScreenState();
}

class _AvailablePickupsScreenState extends State<AvailablePickupsScreen> {
  bool _loading = true;
  List<dynamic> _pickups = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailablePickups();
  }

  Future<void> _fetchAvailablePickups() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAvailablePickups();
      setState(() => _pickups = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load available pickups: $e")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _claimPickup(int id) async {
    try {
      final result = await ApiService.claimPickup(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup claimed")),
      );
      _fetchAvailablePickups(); // refresh list after claiming
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to claim pickup: $e")),
      );
    }
  }

  String _dateStr(String? s) {
    if (s == null) return "";
    try {
      final dt = DateTime.parse(s);
      return DateFormat("MMM d, yyyy hh:mm a").format(dt);
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Pickups"),
        backgroundColor: Colors.green,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pickups.isEmpty
              ? const Center(child: Text("No available pickups"))
              : RefreshIndicator(
                  onRefresh: _fetchAvailablePickups,
                  child: ListView.builder(
                    itemCount: _pickups.length,
                    itemBuilder: (context, index) {
                      final p = _pickups[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.green),
                          title: Text("${p["address"] ?? "Unknown address"}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Weight: ${p["trash_weight"] ?? "N/A"} kg"),
                              Text("Waste type: ${p["waste_type_display"] ?? p["waste_type"]}"),
                              Text("Scheduled: ${_dateStr(p["scheduled_date"])}"),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _claimPickup(p["id"]),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Claim"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
