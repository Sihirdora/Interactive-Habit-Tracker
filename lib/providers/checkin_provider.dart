// lib/providers/checkin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/check_in_model.dart';
import '../models/habit_model.dart'; 
import '../services/supabase_service.dart';
import 'habit_provider.dart'; // Digunakan untuk mengakses supabaseServiceProvider

// Catatan: Asumsi 'supabaseServiceProvider' tersedia melalui habit_provider.dart

// FutureProvider.family: Mendapatkan semua Check-In untuk satu Kebiasaan (READ)
final checkInsByHabitIdProvider = 
    FutureProvider.family<List<CheckIn>, int>((ref, habitId) async {
  
  final service = ref.watch(supabaseServiceProvider);
  return service.getCheckInsForHabit(habitId);
});

class CheckInNotifier extends StateNotifier<void> {
  final SupabaseService _service;
  final Ref _ref;

  CheckInNotifier(this._service, this._ref) : super(null); 

  // CREATE / LOG (Menggunakan Upsert)
  Future<void> performCheckIn({
    required Habit habit,
    required double progressValue,
    String? notes,
  }) async {
    final today = DateTime.now();
    final checkInDate = DateTime(today.year, today.month, today.day);
    final bool isCompleted = progressValue >= habit.targetValue;

    final newCheckIn = CheckIn(
      id: 0, // Akan diabaikan oleh Supabase saat CREATE/UPSERT
      habitId: habit.id,
      checkInDate: checkInDate,
      progressValue: progressValue,
      isCompleted: isCompleted,
      notes: notes,
    );
    
    await _service.logCheckIn(newCheckIn); // Asumsi logCheckIn menangani CREATE/UPSERT

    _ref.invalidate(checkInsByHabitIdProvider(habit.id));
  }
  
  // --- UPDATE LOGIC (Baru Ditambahkan) ---
  Future<void> updateEntry(CheckIn entry) async {
    // Note: Asumsi SupabaseService memiliki fungsi updateCheckIn(CheckIn entry)
    await _service.updateCheckIn(entry);
    
    // Invalidasi untuk merefresh data check-in di UI
    _ref.invalidate(checkInsByHabitIdProvider(entry.habitId));
  }

  // --- DELETE LOGIC (Baru Ditambahkan) ---
  Future<void> deleteEntry(int entryId, int habitId) async {
    // Note: Asumsi SupabaseService memiliki fungsi deleteCheckIn(int id)
    await _service.deleteCheckIn(entryId);
    
    // Invalidasi untuk merefresh data check-in di UI
    _ref.invalidate(checkInsByHabitIdProvider(habitId));
  }
}

final checkInNotifierProvider = StateNotifierProvider<CheckInNotifier, void>(
  (ref) {
    final service = ref.watch(supabaseServiceProvider);
    return CheckInNotifier(service, ref);
  },
);