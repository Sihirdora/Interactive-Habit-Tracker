// lib/providers/checkin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/check_in_model.dart';
import '../models/habit_model.dart'; 
import '../services/supabase_service.dart';
import 'habit_provider.dart'; // Digunakan untuk mengakses supabaseServiceProvider

// FutureProvider.family: Mendapatkan semua Check-In untuk satu Kebiasaan
final checkInsByHabitIdProvider = 
    FutureProvider.family<List<CheckIn>, int>((ref, habitId) async {
  
  final service = ref.watch(supabaseServiceProvider);
  return service.getCheckInsForHabit(habitId);
});

class CheckInNotifier extends StateNotifier<void> {
  final SupabaseService _service;
  final Ref _ref;

  CheckInNotifier(this._service, this._ref) : super(null); 

  Future<void> performCheckIn({
    required Habit habit,
    required double progressValue,
    String? notes,
  }) async {
    final today = DateTime.now();
    // Pastikan tanggal hanya berisi yyyy-mm-dd
    final checkInDate = DateTime(today.year, today.month, today.day);

    final bool isCompleted = progressValue >= habit.targetValue;

    final newCheckIn = CheckIn(
      id: 0, 
      habitId: habit.id,
      checkInDate: checkInDate,
      progressValue: progressValue,
      isCompleted: isCompleted,
      notes: notes,
    );
    
    await _service.logCheckIn(newCheckIn);

    // Invalidasi untuk merefresh data check-in di UI
    _ref.invalidate(checkInsByHabitIdProvider(habit.id));
  }
}

final checkInNotifierProvider = StateNotifierProvider<CheckInNotifier, void>(
  (ref) {
    final service = ref.watch(supabaseServiceProvider);
    return CheckInNotifier(service, ref);
  },
);