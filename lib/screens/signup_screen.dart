// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();

  bool _isLoading = false;

  void _register() async {
    if (_restaurantController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your restaurant name.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final emailText = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();

    bool success = await ApiService.register(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      email: emailText,
      restaurantName: _restaurantController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DARWCOS",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Get Started",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name / Username",
                        labelStyle: TextStyle(color: darwcosGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 1),
                        ),
                        prefixIcon: Icon(Icons.person, color: darwcosGreen),
                        border: OutlineInputBorder(),
                      ),
                      cursorColor: darwcosGreen,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email (optional)",
                        labelStyle: TextStyle(color: darwcosGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 1),
                        ),
                        prefixIcon: Icon(Icons.email, color: darwcosGreen),
                        border: OutlineInputBorder(),
                      ),
                      cursorColor: darwcosGreen,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: darwcosGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 1),
                        ),
                        prefixIcon: Icon(Icons.lock, color: darwcosGreen),
                        border: OutlineInputBorder(),
                      ),
                      cursorColor: darwcosGreen,
                    ),
                    const SizedBox(height: 16),

                    // Restaurant
                    TextField(
                      controller: _restaurantController,
                      decoration: const InputDecoration(
                        labelText: "Restaurant Name",
                        labelStyle: TextStyle(color: darwcosGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darwcosGreen, width: 1),
                        ),
                        prefixIcon: Icon(Icons.store, color: darwcosGreen),
                        border: OutlineInputBorder(),
                      ),
                      cursorColor: darwcosGreen,
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 3,
                              ),
                              onPressed: _register,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an Account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: darwcosGreen,
                          ),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                              color: darwcosGreen,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
