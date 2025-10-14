// lib/screens/assigned_pickups_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AssignedPickupsScreen extends StatefulWidget {
  final bool includeHistory;
  const AssignedPickupsScreen({super.key, this.includeHistory = false});

  @override
  State<AssignedPickupsScreen> createState() => _AssignedPickupsScreenState();
}

class _AssignedPickupsScreenState extends State<AssignedPickupsScreen> {
  bool _loading = true;
  List<dynamic> _pickups = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDriverPickups(
        includeHistory: widget.includeHistory,
      );
      setState(() => _pickups = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load pickups: $e")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _startPickup(int id) async {
    try {
      final result = await ApiService.startPickup(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup started")),
      );
      _fetch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start pickup: $e")),
      );
    }
  }

  Future<void> _completePickup(int id) async {
    try {
      final result = await ApiService.completePickup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup completed")),
      );
      Navigator.pop(context, true); // ✅ return to dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to complete pickup: $e")),
      );
    }
  }

  Future<void> _cancelPickup(int id) async {
    try {
      final result = await ApiService.cancelPickup(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Pickup cancelled")),
      );
      Navigator.pop(context, true); // ✅ return to dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel pickup: $e")),
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
        title: Text(widget.includeHistory ? "Completed Pickups" : "Assigned Pickups"),
        backgroundColor: Colors.green,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pickups.isEmpty
              ? const Center(child: Text("No pickups found"))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    itemCount: _pickups.length,
                    itemBuilder: (context, index) {
                      final p = _pickups[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping, color: Colors.green),
                          title: Text("${p["address"] ?? "Unknown address"}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Weight: ${p["trash_weight"] ?? "N/A"} kg"),
                              Text("Waste type: ${p["waste_type_display"] ?? p["waste_type"]}"),
                              Text("Scheduled: ${_dateStr(p["scheduled_date"])}"),
                              Text("Status: ${p["status"]}"),
                            ],
                          ),
                          trailing: !widget.includeHistory
                              ? PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == "start") _startPickup(p["id"]);
                                    if (val == "complete") _completePickup(p["id"]);
                                    if (val == "cancel") _cancelPickup(p["id"]);
                                  },
                                  itemBuilder: (_) => [
                                    if (p["status"] == "pending")
                                      const PopupMenuItem(
                                        value: "start",
                                        child: Text("Start"),
                                      ),
                                    if (p["status"] == "in_progress")
                                      const PopupMenuItem(
                                        value: "complete",
                                        child: Text("Complete"),
                                      ),
                                    const PopupMenuItem(
                                      value: "cancel",
                                      child: Text("Cancel"),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
