// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_wrapper.dart';
import 'screens/welcome_screen.dart';

// Variabel menggunakan lowerCamelCase
const supabaseUrl = 'https://krelridtfqpyspmdhzoj.supabase.co'; 
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyZWxyaWR0ZnFweXNwbWRoem9qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMTY2NTcsImV4cCI6MjA3OTY5MjY1N30.hlJIibZfYIS3xVa4GqIs7DB1FoHdaHS2JI2b01cjfDc'; 

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
      home: const WelcomeScreen(), 
    );
  }
}