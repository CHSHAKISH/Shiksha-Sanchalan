import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiksha_sanchalan/screens/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Using an Image asset for the logo
              Image.asset(
                'assets/logo.png', // Make sure you have this file in assets/logo.png
                height: 150,
              ),

              // Using an Image asset for the illustration
              Image.asset(
                'assets/onboarding_illustration.png', // Make sure you have this file in assets/onboarding.png
                height: 300,
              ),

              const Column(
                children: [
                  Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Say goodbye to chaos — manage seating, faculty, and timetables effortlessly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding(context),
                  child: const Text("Start Managing Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
