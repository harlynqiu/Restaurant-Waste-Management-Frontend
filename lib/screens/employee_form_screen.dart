// lib/screens/employee_form_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final int? employeeId;
  final String? name;
  final String? position;
  final String? contact;

  const EmployeeFormScreen({
    super.key,
    this.employeeId,
    this.name,
    this.position,
    this.contact,
  });

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.name != null) _nameController.text = widget.name!;
    if (widget.position != null) _positionController.text = widget.position!;
    if (widget.contact != null) _contactController.text = widget.contact!;
  }

  // ---------------- SAVE / UPDATE STAFF ----------------
  Future<void> _saveEmployee() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty || position.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all required fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.employeeId == null) {
      success = await ApiService.addStaff(name, position, contact);
    } else {
      success = await ApiService.updateStaff(
        widget.employeeId!,
        name,
        position,
        contact,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.employeeId == null
              ? "Employee added successfully!"
              : "Employee updated successfully!"),
          backgroundColor: darwcosGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.employeeId == null
              ? "Failed to add employee."
              : "Failed to update employee."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------- INPUT DECORATION ----------------
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: darwcosGreen),
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Colors.black45),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darwcosGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
    );
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employeeId != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darwcosGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Edit Employee" : "Add Employee",
          style: const TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: darwcosGreen.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(
                      isEditing
                          ? Icons.manage_accounts_outlined
                          : Icons.person_add_alt_1_rounded,
                      color: darwcosGreen,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      isEditing
                          ? "Update Employee Details"
                          : "Add New Employee",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 👤 Full Name
                  TextField(
                    controller: _nameController,
                    decoration:
                        _inputDecoration("Full Name", Icons.person_outline),
                  ),
                  const SizedBox(height: 18),

                  // 🧰 Position
                  TextField(
                    controller: _positionController,
                    decoration:
                        _inputDecoration("Position", Icons.work_outline),
                  ),
                  const SizedBox(height: 18),

                  // ☎️ Contact
                  TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _inputDecoration("Contact (Optional)", Icons.phone),
                  ),
                  const SizedBox(height: 32),

                  // 💾 Save Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darwcosGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: darwcosGreen.withOpacity(0.3),
                            ),
                            icon: Icon(
                              isEditing
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              isEditing
                                  ? "Update Employee"
                                  : "Save Employee",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _saveEmployee,
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
