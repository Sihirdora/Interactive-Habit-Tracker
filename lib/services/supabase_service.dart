import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_model.dart';
import '../models/check_in_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // READ: Stream untuk mendapatkan semua kebiasaan secara realtime
  Stream<List<Habit>> getHabitsStream() {
    return _client
        .from('habits')
        .stream(primaryKey: ['id'])
        .order('start_date', ascending: true)
        .map((maps) => maps.map((map) => Habit.fromJson(map)).toList());
  }

  // CREATE: Menambahkan kebiasaan baru & MENGEMBALIKAN DATA BARU
  // Perhatikan tipe kembalian: Future<Habit>, bukan Future<void>
  Future<Habit> addHabit(Habit habit) async {
    final response = await _client
        .from('habits')
        .insert(habit.toJson())
        .select() // .select() penting agar Supabase mengembalikan data yang baru diinsert
        .single();
    
    return Habit.fromJson(response);
  }

  // UPDATE PROGRESS HARIAN (JSONB)
  Future<void> updateHabitProgress(int habitId, String dateKey, double value) async {
    try {
      final response = await _client
          .from('habits')
          .select('daily_progress')
          .eq('id', habitId)
          .single();

      Map<String, dynamic> currentProgress = {};
      
      if (response['daily_progress'] != null) {
        currentProgress = Map<String, dynamic>.from(response['daily_progress']);
      }

      currentProgress[dateKey] = value;

      await _client
          .from('habits')
          .update({'daily_progress': currentProgress})
          .eq('id', habitId);
          
    } catch (e) {
      print("Error updating daily_progress: $e");
    }
  }

  // --- Operasi Check-In (Opsional/Fitur Lama) ---

  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final response = await _client.from('checkins')
        .select()
        .eq('habit_id', habitId)
        .order('check_in_date', ascending: false);
    
    return (response as List).map((json) => CheckIn.fromJson(json)).toList();
  }

  Future<void> logCheckIn(CheckIn checkIn) async {
    await _client.from('checkins').upsert(
      checkIn.toJson(), 
      onConflict: 'habit_id, check_in_date'
    );
  }
  Future<void> updateCheckIn(CheckIn entry) async {
  await _client.from('checkins')
      .update(entry.toJson())
      .eq('id', entry.id);
  }

  // DELETE Check-In
  Future<void> deleteCheckIn(int entryId) async {
    await _client.from('checkins')
        .delete()
        .eq('id', entryId);
  }
  Future<void> updateHabit(Habit habit) async {
  await _client.from('habits')
      .update(habit.toJson())
      .eq('id', habit.id);
}

// DELETE Habit
Future<void> deleteHabit(int habitId) async {
  // CASCADE DELETE akan menghapus semua CheckIn terkait
  await _client.from('habits')
      .delete()
      .eq('id', habitId);
}
}