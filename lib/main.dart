// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

// Variabel menggunakan lowerCamelCase
const supabaseUrl = 'https://jchatgthjwemgapwqygu.supabase.co'; 
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjaGF0Z3RoandlbWdhcHdxeWd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MjYwODksImV4cCI6MjA3OTIwMjA4OX0.G039DkyDEVr45arIVu3jdeUkC7NBnIxiTmlAIGNNOz0'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
      home: const HomeScreen(), 
    );
  }
}