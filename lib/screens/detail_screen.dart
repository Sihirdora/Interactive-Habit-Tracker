// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../providers/checkin_provider.dart';

class DetailScreen extends ConsumerWidget {
  final Habit habit;
  
  const DetailScreen({required this.habit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInNotifier = ref.watch(checkInNotifierProvider.notifier);
    final checkInsAsync = ref.watch(checkInsByHabitIdProvider(habit.id));
    final primaryColor = Color(habit.colorCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(habit, primaryColor),
              const SizedBox(height: 20),

              _buildProgressChartPlaceholder(primaryColor),
              const SizedBox(height: 30),

              _buildStreakAndStatus(checkInsAsync, primaryColor),
              const SizedBox(height: 30),

              _buildInteractiveCheckIn(context, habit, checkInNotifier),
              const SizedBox(height: 30),
              
              _buildCheckInHistory(context, checkInsAsync), 
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(Habit habit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.description ?? "No description provided.",
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Text(
          'Target: ${habit.targetValue} ${habit.unit ?? ''} (${habit.targetType})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // FIX: Mengganti withOpacity yang usang
  Widget _buildProgressChartPlaceholder(Color color) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()), // Alpha 25
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          "Placeholder for Progress Chart (fl_chart)",
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  Widget _buildStreakAndStatus(AsyncValue checkInsAsync, Color color) {
    return checkInsAsync.when(
      loading: () => const Center(child: Text("Calculating streak...")),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (checkIns) {
        // [DEAD CODE FIX]: Hanya return widget
        final currentStreak = 5; 
        final longestStreak = 8;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard("Current Streak", "$currentStreak Days", color),
            _buildStatCard("Longest Streak", "$longestStreak Days", color),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 150,
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // FIX: Menggunakan async dan await untuk memastikan flow control yang jelas
  Widget _buildInteractiveCheckIn(
    BuildContext context, 
    Habit habit, 
    CheckInNotifier checkInNotifier
  ) {
    final isCheckedIn = false; 

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: isCheckedIn ? Colors.grey : Color(habit.colorCode),
      ),
      onPressed: isCheckedIn ? null : () async {
        if (habit.targetType != 'BOOLEAN') {
          // Menunggu dialog mengembalikan nilai
          await _showProgressDialog(context, habit, checkInNotifier); 
        } else {
          // Menunggu aksi check-in
          await checkInNotifier.performCheckIn( 
            habit: habit,
            progressValue: 1.0,
            notes: "Boolean check-in",
          );
        }
      },
      icon: Icon(isCheckedIn ? Icons.check_circle : Icons.add_task),
      label: Text(
        isCheckedIn ? 'Checked In Today!' : 'Log Today\'s Progress',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
  
  // FIX: Mengembalikan Future<void> dan pop dengan nilai
  Future<void> _showProgressDialog(BuildContext context, Habit habit, CheckInNotifier checkInNotifier) async {
    final TextEditingController progressController = TextEditingController();
    
    // Mengembalikan hasil (progress value) dari dialog
    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Log Progress (${habit.unit ?? 'Count'})'),
          content: TextField(
            controller: progressController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'How much did you do?',
              suffixText: habit.unit,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(), 
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                final progress = double.tryParse(progressController.text);
                if (progress != null && progress >= 0) {
                  Navigator.of(dialogContext).pop(progress); // Pop dengan nilai progress
                }
                // Tidak ada kode mati di sini
              },
            ),
          ],
        );
      },
    );

    // Jalankan aksi hanya jika nilai progress diterima
    if (result != null) {
      await checkInNotifier.performCheckIn(
        habit: habit,
        progressValue: result,
      );
    }
  }

  Widget _buildCheckInHistory(BuildContext context, AsyncValue checkInsAsync) { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Check-Ins',
          style: Theme.of(context).textTheme.titleLarge, 
        ),
        checkInsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text('Error loading history: $err'),
          data: (checkIns) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkIns.length > 5 ? 5 : checkIns.length, 
              itemBuilder: (context, index) {
                final checkIn = checkIns[index];
                final isCompleted = checkIn.progressValue >= habit.targetValue; 
                
                return ListTile(
                  leading: Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                  title: Text(checkIn.checkInDate.toIso8601String().substring(0, 10)),
                  subtitle: Text('Progress: ${checkIn.progressValue} ${habit.unit ?? ''}'),
                );
              },
            );
          },
        ),
      ],
    );
  }
}