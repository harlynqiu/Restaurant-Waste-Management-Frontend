import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reset_confirm_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _loading = false;
  bool _showManualConfirm = false;

  void _resetPassword() async {
    setState(() => _loading = true);
    bool success = await ApiService.resetPassword(_emailController.text.trim());
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✅ Password reset link sent! Check your email.")),
      );
      setState(() => _showManualConfirm = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Failed to send reset link. Please try again.")),
      );
    }
  }

  void _openConfirm() {
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
        backgroundColor: const Color.fromARGB(255, 1, 87, 4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your registered email address. We'll send you a link to reset your password.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 87, 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _resetPassword,
                    child: const Text(
                      "Send Reset Link",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
            if (_showManualConfirm) ...[
              const SizedBox(height: 32),
              const Text(
                "Manually test reset link by entering UID and Token:",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 12),
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
                  backgroundColor: const Color.fromARGB(255, 1, 87, 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _openConfirm,
                child: const Text(
                  "Proceed to Reset Form",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
