// lib/screens/reset_request_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reset_confirm_screen.dart';

class ResetRequestScreen extends StatefulWidget {
  const ResetRequestScreen({super.key});

  @override
  State<ResetRequestScreen> createState() => _ResetRequestScreenState();
}

class _ResetRequestScreenState extends State<ResetRequestScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _showManualConfirm = false; // for testing uid/token manually
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  void _requestReset() async {
    setState(() => _loading = true);

    final success = await ApiService.resetPassword(_emailController.text.trim());

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent!")),
      );
      // Show manual confirmation fields for testing
      setState(() => _showManualConfirm = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send reset email. Try again.")),
      );
    }
  }

  void _openConfirmScreen() {
    final uid = _uidController.text.trim();
    final token = _tokenController.text.trim();

    if (uid.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both UID and Token.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetConfirmScreen(uid: uid, token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your email to request a password reset.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Email input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Send request button
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _requestReset,
                    child: const Text(
                      "Send Reset Email",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

            // --- Manual confirm fields (for development / testing) ---
            if (_showManualConfirm) ...[
              const SizedBox(height: 40),
              const Text(
                "Enter UID and Token (from email) manually to continue:",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: "UID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: "Token",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _openConfirmScreen,
                child: const Text(
                  "Proceed to Reset Form",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
