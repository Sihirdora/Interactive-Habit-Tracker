// lib/providers/today_progress_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import 'habit_provider.dart'; // Import habitsProvider
import 'checkin_provider.dart'; // Import checkInsByHabitIdProvider

// Struktur data untuk menyimpan Habit + Progress gabungan
class HabitWithProgress {
  final Habit habit;
  final double progressValue; // Nilai progress hari ini (misal: 0.5 atau 1.0)
  final double progressPercent; // Persentase (0.0 - 1.0)

  HabitWithProgress({
    required this.habit,
    required this.progressValue,
    required this.progressPercent,
  });
}

// Provider yang menggabungkan Habit dan Progress Harian
final todayHabitProgressProvider = 
    FutureProvider<List<HabitWithProgress>>((ref) async {

  final habitsAsync = ref.watch(habitsProvider);
  if (!habitsAsync.hasValue) {
    // Jika habit belum dimuat, kembalikan list kosong/tunggu
    return [];
  }
  
  final habits = habitsAsync.value!;
  final results = <HabitWithProgress>[];
  final today = DateTime.now();

  for (final habit in habits.where((h) => h.isActive)) {
    // Ambil semua check-in untuk habit ini (asumsi data check-in sudah difetch)
    final checkInsAsync = await ref.watch(checkInsByHabitIdProvider(habit.id).future);

    double totalProgressToday = 0.0;
    
    // Hitung total progress untuk hari ini saja
    for (var checkIn in checkInsAsync) {
      if (checkIn.checkInDate.year == today.year && 
          checkIn.checkInDate.month == today.month && 
          checkIn.checkInDate.day == today.day) {
        // Karena `logCheckIn` di CheckInNotifier sudah menimpa (upsert) nilai total, 
        // kita ambil progressValue terakhir (yang tersimpan di DB) sebagai progress harian hari ini.
        totalProgressToday = checkIn.progressValue; 
        break; // Jika Anda mengasumsikan hanya ada 1 entry per hari yang menyimpan nilai kumulatif.
      }
    }
    
    // Hitung persentase
    double percent = (habit.targetValue > 0) 
        ? (totalProgressToday / habit.targetValue) 
        : 0.0;
        
    percent = percent.clamp(0.0, 1.0);

    results.add(HabitWithProgress(
      habit: habit,
      progressValue: totalProgressToday,
      progressPercent: percent,
    ));
  }

  return results;
});

// Provider untuk Menghitung Statistik Ringkasan (Opsional tapi lebih bersih)
final todaySummaryProvider = Provider<({int totalActive, int completed, double overallRate})>((ref) {
  final dataAsync = ref.watch(todayHabitProgressProvider);
  
  if (!dataAsync.hasValue) {
    return (totalActive: 0, completed: 0, overallRate: 0.0);
  }
  
  final data = dataAsync.value!;
  int totalActive = data.length;
  int completed = data.where((item) => item.progressPercent >= 1.0).length;
  double totalProgressSum = data.fold(0.0, (sum, item) => sum + item.progressPercent);
  
  double overallRate = (totalActive > 0) ? (totalProgressSum / totalActive) : 0.0;
  
  return (
    totalActive: totalActive, 
    completed: completed, 
    overallRate: overallRate.clamp(0.0, 1.0)
  );
});