import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/habit_model.dart';

// 1. Provider untuk Service (Hanya Supabase)
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// 2. Notifier Utama
class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final SupabaseService _supabaseService;
  
  // Hapus parameter NotificationService
  HabitsNotifier(this._supabaseService) 
      : super(const AsyncValue.loading()) {
    _fetchHabits();
  }

  // --- FUNGSI 1: MENDENGARKAN DATA DARI SUPABASE (STREAM) ---
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

  // --- FUNGSI 2: MENAMBAH HABIT BARU ---
  Future<void> addHabit(Habit habit) async {
    try {
      // Kita hanya simpan ke Database.
      // Tidak ada lagi penjadwalan notifikasi di sini.
      await _supabaseService.addHabit(habit);
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // --- FUNGSI 3: UPDATE PROGRESS (REAL-TIME UI) ---
  Future<void> incrementProgress(int habitId, double amount) async {
    final currentState = state.value;
    if (currentState == null) return;

    final todayKey = DateTime.now().toString().split(' ')[0];

    // A. OPTIMISTIC UPDATE (Update UI Dulu)
    final updatedHabits = currentState.map((habit) {
      if (habit.id == habitId) {
        final currentVal = habit.dailyProgress[todayKey] ?? 0.0;
        
        double newVal;
        if (habit.targetType == 'BOOLEAN') {
          newVal = habit.targetValue; 
        } else {
          newVal = currentVal + amount;
        }

        final newProgressMap = Map<String, double>.from(habit.dailyProgress);
        newProgressMap[todayKey] = newVal;

        return habit.copyWith(dailyProgress: newProgressMap);
      }
      return habit;
    }).toList();

    state = AsyncValue.data(updatedHabits);

    // B. PERSISTENCE (Simpan ke Supabase)
    try {
      final updatedHabit = updatedHabits.firstWhere((h) => h.id == habitId);
      final valueToSend = updatedHabit.dailyProgress[todayKey]!;

      await _supabaseService.updateHabitProgress(habitId, todayKey, valueToSend);
    } catch (e) {
      print("Gagal menyimpan progress ke Supabase: $e");
    }
  }
}

// 3. Global Provider
final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
  (ref) {
    final supabase = ref.watch(supabaseServiceProvider);
    // Hapus notification provider
    return HabitsNotifier(supabase);
  },
);