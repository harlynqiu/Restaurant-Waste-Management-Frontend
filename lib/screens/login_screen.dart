// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import 'dashboard.dart';
import 'driver_dashboard.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ---------------- LOGIN FUNCTION ----------------
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both username and password.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.login(username, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password.")),
      );
      return;
    }

    try {
      // ✅ Fetch current user info from backend and preferences
      final user = await ApiService.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString("role") ?? user?["role"] ?? "owner";

      print("🔑 Logged in role: $role");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Login successful as $role!")),
      );

      // ✅ Role-based navigation
      Widget targetScreen;
      if (role.toLowerCase() == "driver") {
        targetScreen = const DriverDashboardScreen();
      } else {
        targetScreen = const DashboardScreen();
      }

      // ✅ Replace entire stack with dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error fetching user info: $e")),
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
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                          "Let's continue making the world a better place one step at a time.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        // Username field
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: "Email or Username",
                            labelStyle: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 1, 87, 4), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 1, 87, 4), width: 1),
                            ),
                            prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 1, 87, 4)),
                          ),
                          cursorColor: const Color.fromARGB(255, 1, 87, 4),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: const TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 1, 87, 4), width: 2),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 1, 87, 4), width: 1),
                            ),
                            prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 1, 87, 4)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: const Color.fromARGB(255, 1, 87, 4),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
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
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 1, 87, 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _login,
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
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
                            icon: const Icon(Icons.g_mobiledata, color: Color.fromARGB(255, 1, 87, 4)),
                            onPressed: () {},
                            label: const Text(
                              "Sign in with Google",
                              style: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
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
                              style: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
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
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 1, 87, 4),
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
