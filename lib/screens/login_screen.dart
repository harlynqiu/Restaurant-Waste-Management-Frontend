// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import 'dashboard.dart';
import 'driver_dashboard.dart';
import 'reset_confirm_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // ---------------- LOGIN FUNCTION ----------------
  Future<void> _login() async {
    setState(() => _isLoading = true);

    bool success = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      try {
        final user = await ApiService.getCurrentUser();
        final prefs = await SharedPreferences.getInstance();

        if (user != null) {
          // Extract possible role fields safely
          final role = (user["user_role"] ??
                  user["role"] ??
                  user["position"] ??
                  "")
              .toString()
              .toLowerCase();

          final groups = List<String>.from(user["groups"] ?? []);

          // Save role in preferences
          await prefs.setString("role", role);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login successful!")),
          );

          // ✅ Decide destination based on role or group name
          final isDriver = role.contains("driver") ||
              groups.any((g) => g.toLowerCase().contains("driver"));

          if (isDriver) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to fetch user info.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching user info: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password.")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 1, 87, 4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/images/white_eagle_logo.png",
                      width: 150,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Welcome to DARWCOS",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The next step to Redefining\nRestaurant Waste Collection",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right login panel
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "D.A.R.W.C.O.S",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 87, 4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 87, 4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Let's continue in making the world a better place one step at a time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        // Username
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: "Email or Username",
                            labelStyle:
                                TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 1, 87, 4),
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 1, 87, 4),
                                  width: 1),
                            ),
                            prefixIcon: Icon(Icons.person,
                                color: Color.fromARGB(255, 1, 87, 4)),
                          ),
                          cursorColor: const Color.fromARGB(255, 1, 87, 4),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            labelStyle:
                                TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 1, 87, 4),
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 1, 87, 4),
                                  width: 1),
                            ),
                            prefixIcon: Icon(Icons.lock,
                                color: Color.fromARGB(255, 1, 87, 4)),
                          ),
                          cursorColor: const Color.fromARGB(255, 1, 87, 4),
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 1, 87, 4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 1, 87, 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  onPressed: _login,
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("or"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google login placeholder
                        SizedBox(
                          width: 250,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata,
                                color: Color.fromARGB(255, 1, 87, 4)),
                            onPressed: () {},
                            label: const Text(
                              "Sign in with Google",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 1, 87, 4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Apple login placeholder
                        SizedBox(
                          width: 250,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.apple, color: Colors.black),
                            onPressed: () {},
                            label: const Text(
                              "Sign in with Apple",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 1, 87, 4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New User? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    const Color.fromARGB(255, 1, 87, 4),
                              ),
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 1, 87, 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            content: Text("Password reset link sent! Check your email.")),
      );
      setState(() => _showManualConfirm = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send reset link. Try again.")),
      );
    }
  }

  void _openConfirm() {
    final uid = _uidController.text.trim();
    final token = _tokenController.text.trim();

    if (uid.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter both UID and Token.")),
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
          title: const Text("Forgot Password"), backgroundColor: Colors.green),
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
                      backgroundColor: Colors.green,
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
                  backgroundColor: Colors.green,
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
