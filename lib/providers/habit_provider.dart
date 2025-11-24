// lib/providers/habit_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/habit_model.dart';

// Inisialisasi SupabaseService
final supabaseServiceProvider = Provider((ref) => SupabaseService());

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final SupabaseService _service;
  
  HabitsNotifier(this._service) : super(const AsyncValue.loading()) {
    _fetchHabits();
  }

  void _fetchHabits() {
    // Listen to the stream for realtime updates
    _service.getHabitsStream().listen(
      (habits) {
        state = AsyncValue.data(habits);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  // CREATE: Dipanggil dari AddHabitScreen
  Future<void> addHabit(Habit habit) async {
    try {
      await _service.addHabit(habit);
      // Stream akan otomatis memperbarui state
    } catch (e, stack) {
      // Handle error jika insert gagal
      state = AsyncValue.error(e, stack);
    }
  }
}

// Global Provider untuk diakses di UI
final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) {
    final service = ref.watch(supabaseServiceProvider);
    return HabitsNotifier(service);
  },
);