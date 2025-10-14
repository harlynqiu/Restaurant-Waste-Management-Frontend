import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart';
import 'login_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    try {
      final employees = await ApiService.getEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading employees: $e")),
      );
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _deleteEmployee(int id) async {
    bool success = await ApiService.deleteEmployee(id);
    if (success) {
      _loadEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee deleted")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete employee")),
      );
    }
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp["name"] ?? "Unnamed",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emp["position"] ?? "Unknown position",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeFormScreen(
                      employeeId: emp["id"],
                      name: emp["name"],
                      position: emp["position"],
                    ),
                  ),
                );
                if (updated == true) {
                  _loadEmployees();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteEmployee(emp["id"]),
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
        title: const Text("Employees"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(
                  child: Text("No employees found",
                      style: TextStyle(fontSize: 16, color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: () async => _loadEmployees(),
                  child: ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final emp = _employees[index];
                      return _buildEmployeeCard(emp);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EmployeeFormScreen()),
          );
          if (added == true) {
            _loadEmployees();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
