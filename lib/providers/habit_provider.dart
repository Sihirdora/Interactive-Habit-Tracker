import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/habit_model.dart';

// 1. Provider untuk Service
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// 2. Notifier Utama
class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final SupabaseService _supabaseService;
  
  HabitsNotifier(this._supabaseService) 
    : super(const AsyncValue.loading()) {
    _fetchHabits();
  }

  // --- FUNGSI 1: MENDENGARKAN DATA DARI SUPABASE (READ) ---
  void _fetchHabits() {
    _supabaseService.getHabitsStream().listen(
      (habits) {
        state = AsyncValue.data(habits);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  // --- FUNGSI 2: MENAMBAH HABIT BARU (CREATE) ---
  Future<void> addHabit(Habit habit) async {
    try {
      await _supabaseService.addHabit(habit);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // --- FUNGSI 3: MENGEDIT HABIT (UPDATE) ---
  // Fungsi ini dipanggil dari EditHabitScreen
  Future<void> updateHabit(Habit habit) async {
    try {
      await _supabaseService.updateHabit(habit);
      // Stream Supabase akan otomatis memperbarui state di atas
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // --- FUNGSI 4: MENGHAPUS HABIT (DELETE) ---
  // Fungsi ini dipanggil dari EditHabitScreen/Delete Confirmation
  Future<void> deleteHabit(int habitId) async {
    try {
      await _supabaseService.deleteHabit(habitId);
      // Stream Supabase akan otomatis memperbarui state di atas
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // --- FUNGSI LAMA YANG DIHAPUS ---
  // Menghapus incrementProgress karena logic tracking kini ada di CheckInNotifier.
}

// 3. Global Provider
final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) {
    final supabase = ref.watch(supabaseServiceProvider);
    return HabitsNotifier(supabase);
  },
);