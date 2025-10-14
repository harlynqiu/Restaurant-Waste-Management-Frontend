// lib/screens/pickup_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class PickupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;
  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  late Map<String, dynamic> p;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    p = Map<String, dynamic>.from(widget.pickup);
  }

  String _date(String? s) {
    if (s == null) return "—";
    try {
      final dt = DateTime.parse(s).toLocal();
      return DateFormat("MMM d, y – hh:mm a").format(dt);
    } catch (_) {
      return s;
    }
  }

  Future<void> _doStart() async {
    setState(() => _busy = true);
    try {
      final updated = await ApiService.startPickup(p["id"]);
      setState(() => p = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup started.")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start: $e")),
      );
    }
    setState(() => _busy = false);
  }

  Future<void> _doComplete() async {
    setState(() => _busy = true);
    try {
      final updated = await ApiService.completePickup(p["id"]);
      setState(() => p = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup completed. Points awarded to customer.")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to complete: $e")),
      );
    }
    setState(() => _busy = false);
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

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case "pending":
        color = Colors.orange;
        break;
      case "in_progress":
        color = Colors.blue;
        break;
      case "completed":
        color = Colors.green;
        break;
      case "cancelled":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  List<Widget> _actions() {
    final status = (p["status"] ?? "").toString();
    if (_busy) {
      return const [CircularProgressIndicator()];
    }
    if (status == "pending") {
      return [
        ElevatedButton.icon(
          onPressed: _doStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text("Start"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ];
    }
    if (status == "in_progress") {
      return [
        ElevatedButton.icon(
          onPressed: _doComplete,
          icon: const Icon(Icons.check),
          label: const Text("Complete"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _doCancel,
          icon: const Icon(Icons.close),
          label: const Text("Cancel"),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ];
    }
    return [
      _statusChip(status),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final status = (p["status"] ?? "").toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Details"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p["address"] ?? "No address",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Scheduled: ${_date(p["scheduled_date"])}",
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        _statusChip(status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (p["trash_weight"] != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.scale, color: Colors.green),
                  title: const Text("Estimated Weight"),
                  subtitle: Text("${p["trash_weight"]} kg"),
                ),
              ),
            if (p["waste_type_display"] != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.green),
                  title: const Text("Waste Type"),
                  subtitle: Text("${p["waste_type_display"]}"),
                ),
              ),
            const Spacer(),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _actions(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
