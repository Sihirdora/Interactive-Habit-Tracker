import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import MainWrapper dari folder screens (sesuai struktur folder Anda)
import 'screens/welcome_screen.dart'; // Untuk halaman awal

// --- KONSTANTA SUPABASE ---
// Ganti dengan Kunci Proyek Anda
const supabaseUrl = 'https://jchatgthjwemgapwqygu.supabase.co'; 
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjaGF0Z3RoandlbWdhcHdxeWd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MjYwODksImV4cCI6MjA3OTIwMjA4OX0.G039DkyDEVr45arIVu3jdeUkC7NBnIxiTmlAIGNNOz0'; 
// --- END KONSTANTA ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI SUPABASE ---
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Bungkus aplikasi dengan ProviderScope untuk Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Set halaman awal ke WelcomeScreen (yang akan push ke MainWrapper)
      home: const WelcomeScreen(), 
    );
  }
}