import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TrashPickupFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pickup; // null = new, not null = edit

  const TrashPickupFormScreen({super.key, this.pickup});

  @override
  State<TrashPickupFormScreen> createState() => _TrashPickupFormScreenState();
}

class _TrashPickupFormScreenState extends State<TrashPickupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _weightController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // radio selection
  String _pickupOption = "now"; // "now" or "schedule"

  // ✅ waste type options
  final Map<String, String> _wasteTypes = {
    "customer": "Customer Food Waste",
    "kitchen": "Kitchen Waste",
    "service": "Food Service Waste",
  };
  String? _selectedWasteType;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.pickup?['address'] ?? "");
    _weightController = TextEditingController(
        text: widget.pickup?['trash_weight']?.toString() ?? "");
    _selectedDate = widget.pickup?['scheduled_date'] != null
        ? DateTime.parse(widget.pickup!['scheduled_date'])
        : null;
    _selectedWasteType = widget.pickup?['waste_type'];

    // if editing and scheduled time exists, parse it
    if (widget.pickup?['scheduled_time'] != null) {
      final timeString = widget.pickup!['scheduled_time']; // e.g. "14:30"
      final parts = timeString.split(":");
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        _pickupOption = "schedule";
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupOption == "schedule" &&
        (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time")),
      );
      return;
    }
    if (_selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select waste type")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // final pickup datetime
    DateTime finalDateTime;
    if (_pickupOption == "now") {
      finalDateTime = DateTime.now();
    } else {
      finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    dynamic result;
    if (widget.pickup == null) {
      result = await ApiService.addTrashPickup(
        finalDateTime,
        double.parse(_weightController.text),
        _addressController.text,
        wasteType: _selectedWasteType!,
      );
    } else {
      result = await ApiService.updateTrashPickup(
        widget.pickup!['id'],
        finalDateTime,
        double.parse(_weightController.text),
        _addressController.text,
        wasteType: _selectedWasteType!,
      );
    }

    setState(() => _isLoading = false);

    // ✅ Handle response
    if (widget.pickup == null) {
      if (result["success"] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pickup added! Points: ${result["points"]}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"] ?? "Failed to add pickup")),
        );
      }
    } else {
      if (result == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pickup updated!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update pickup")),
        );
      }
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.pickup == null ? "Add Pickup" : "Edit Pickup"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      prefixIcon: Icon(Icons.location_on, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? "Enter an address"
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: "Weight (kg)",
                      prefixIcon: Icon(Icons.scale, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? "Enter weight"
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Waste Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedWasteType,
                    items: _wasteTypes.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: "Type of Waste",
                      prefixIcon:
                          Icon(Icons.delete_outline, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        setState(() => _selectedWasteType = val),
                    validator: (value) =>
                        value == null ? "Select waste type" : null,
                  ),
                  const SizedBox(height: 24),

                  // Pickup Option
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pickup Option",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      RadioListTile<String>(
                        title: const Text("Pick up now"),
                        value: "now",
                        activeColor: Colors.green,
                        groupValue: _pickupOption,
                        onChanged: (val) =>
                            setState(() => _pickupOption = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text("Schedule a time"),
                        value: "schedule",
                        activeColor: Colors.green,
                        groupValue: _pickupOption,
                        onChanged: (val) =>
                            setState(() => _pickupOption = val!),
                      ),
                    ],
                  ),

                  if (_pickupOption == "schedule") ...[
                    Row(
                      children: [
                        Text(
                          _selectedDate == null
                              ? "No date selected"
                              : "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text("Pick Date"),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _selectedTime == null
                              ? "No time selected"
                              : "Time: ${_selectedTime!.format(context)}",
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _pickTime,
                          child: const Text("Pick Time"),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              widget.pickup == null
                                  ? "Add Pickup"
                                  : "Save Changes",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _submit,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
