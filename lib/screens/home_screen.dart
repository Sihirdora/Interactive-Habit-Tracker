// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart'; 
import 'detail_screen.dart'; // Import DetailScreen

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading habits: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No habits yet. Click + to add one!'));
          }
          
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    // FIX: Mengganti withOpacity yang usang
                    backgroundColor: Color(habit.colorCode).withAlpha((255 * 0.8).round()),
                    child: Text(habit.name[0]),
                  ),
                  title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Target: ${habit.targetValue} ${habit.unit ?? ''} (${habit.targetType})'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigasi ke DetailScreen
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => DetailScreen(habit: habit)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddHabitScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}