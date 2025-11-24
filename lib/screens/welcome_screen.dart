import 'package:flutter/material.dart';
import 'package:project/screens/main_wrapper.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang putih atau warna terang
      backgroundColor: Colors.white, 
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. Ilustrasi / Logo (Gunakan Icon Placeholder) ---
            Icon(
              Icons.track_changes,
              size: 150,
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 30),

            // --- 2. Judul Aplikasi ---
            Text(
              'Interactive Habit Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 15),

            // --- 3. Deskripsi Singkat ---
            const Text(
              'Build better habits, track your progress, and see your streaks grow. Your journey to a better you starts here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 60),

            // --- 4. Tombol Utama (Call to Action) ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Arahkan ke HomeScreen (atau LoginScreen)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainWrapper(),
                    ),
                  );
                },
                child: const Text(
                  'Start Building Habits',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}