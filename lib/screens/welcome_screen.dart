import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // 📱 Mobile layout (column)
            return Column(
              children: [
                // Top image card
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/philippine_eagle.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildRightSide(context),
                ),
              ],
            );
          } else {
            // 💻 Desktop/Web layout (row)
            return Row(
              children: [
                // ✅ Left panel now matches right card design
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/philippine_eagle.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildRightSide(context),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ✅ Right-side card
  Widget _buildRightSide(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, // left-aligned text
          children: [
           
            Center(
              child: Image.asset(
                "assets/images/black_philippine_eagle.png",
                width: 200, // smaller logo
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Left-aligned slogan
            RichText(
              textAlign: TextAlign.left,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: "Radiate "),
                  TextSpan(
                    text: "Pride.",
                    style: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                  ),
                  TextSpan(text: "\nRadiate "),
                  TextSpan(
                    text: "Cleanliness",
                    style: TextStyle(color: Color.fromARGB(255, 1, 87, 4)),
                  ),
                  TextSpan(text: "."),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ✅ Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 87, 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("New User? "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 1, 87, 4), // ✅ ripple + text color
                  ),
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 1, 87, 4), // ✅ same green tone
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
