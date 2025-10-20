// lib/screens/employee_list_screen.dart
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
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  List<dynamic> _staff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staffList = await ApiService.getStaff();
      setState(() {
        _staff = staffList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading staff: $e")),
      );
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _deleteStaff(int id) async {
    final success = await ApiService.deleteStaff(id);
    if (success) {
      _loadStaff();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete employee")),
      );
    }
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final bool isActive = staff["is_active"] ?? true;

    return Align(
      alignment: Alignment.centerLeft, // ✅ Align card to the side
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420), // ✅ Make card smaller
          child: Card(
            elevation: 4,
            color: Colors.white,
            shadowColor: darwcosGreen.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧑 Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: darwcosGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: darwcosGreen, size: 28),
                  ),
                  const SizedBox(width: 14),

                  // 📋 Staff Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff["name"] ?? "Unnamed",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.work_outline,
                                color: Colors.black45, size: 15),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                staff["position"] ?? "Unknown position",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (staff["contact"] != null &&
                            (staff["contact"] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.black45, size: 15),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    staff["contact"],
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? "Active" : "Inactive",
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✏️ Edit Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    ),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeFormScreen(
                            employeeId: staff["id"],
                            name: staff["name"],
                            position: staff["position"],
                          ),
                        ),
                      );
                      if (updated == true) {
                        _loadStaff();
                      }
                    },
                  ),

                  // 🗑 Delete Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, color: Colors.red, size: 18),
                    ),
                    onPressed: () => _deleteStaff(staff["id"]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🌿 AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: const Text(
          "Staff Members",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: darwcosGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: darwcosGreen),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),

      // 📋 Staff List
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? const Center(
                  child: Text(
                    "No staff members found",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStaff,
                  color: darwcosGreen,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(top: 12, bottom: 100, right: 16),
                    itemCount: _staff.length,
                    itemBuilder: (context, index) {
                      final staff = _staff[index];
                      return _buildStaffCard(staff);
                    },
                  ),
                ),

      // ➕ Add Staff Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darwcosGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Staff",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmployeeFormScreen(),
            ),
          );
          if (added == true) {
            _loadStaff();
          }
        },
      ),
    );
  }
}
