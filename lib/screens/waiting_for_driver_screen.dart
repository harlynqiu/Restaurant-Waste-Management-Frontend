import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WaitingForDriverScreen extends StatefulWidget {
  final int pickupId;
  const WaitingForDriverScreen({super.key, required this.pickupId});

  @override
  State<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen> {
  late Timer _timer;
  bool _driverAssigned = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pickup = await ApiService.getPickupById(widget.pickupId);
      if (pickup != null) {
        if (pickup["driver"] != null && pickup["status"] == "in_progress") {
          setState(() => _driverAssigned = true);
          _timer.cancel();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("A driver has accepted your pickup!")),
            );
            Navigator.pop(context, true);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: !_driverAssigned
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    "Finding a nearby driver...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text("Please wait while we connect you with one."),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () {
                      _cancelled = true;
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel Booking"),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
