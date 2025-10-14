import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final int? employeeId;
  final String? name;
  final String? position;

  const EmployeeFormScreen({
    super.key,
    this.employeeId,
    this.name,
    this.position,
  });

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.name != null) _nameController.text = widget.name!;
    if (widget.position != null) _positionController.text = widget.position!;
  }

  void _saveEmployee() async {
    setState(() => _isLoading = true);

    bool success;
    if (widget.employeeId == null) {
      // Add new employee
      success = await ApiService.addEmployee(
        _nameController.text,
        _positionController.text,
      );
    } else {
      // Update existing employee
      success = await ApiService.updateEmployee(
        widget.employeeId!,
        _nameController.text,
        _positionController.text,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.employeeId == null
              ? "Failed to add employee"
              : "Failed to update employee"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employeeId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Employee" : "Add Employee"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: "Position"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveEmployee,
                    child: Text(isEditing ? "Update" : "Save"),
                  ),
          ],
        ),
      ),
    );
  }
}
