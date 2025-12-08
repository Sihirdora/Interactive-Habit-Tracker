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
  Future<Habit> addHabit(Habit habit) async {
    final response = await _client
        .from('habits')
        .insert(habit.toJson())
        .select() 
        .single();
    
    return Habit.fromJson(response);
  }

  // UPDATE PROGRESS HARIAN (JSONB) - DEPRECATED: Sebaiknya gunakan tabel CheckIn
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

  // --- Operasi Check-In ---

  // READ: Mendapatkan semua Check-In untuk satu Habit
  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final response = await _client.from('checkins')
        .select()
        .eq('habit_id', habitId)
        .order('check_in_date', ascending: false);
    
    return (response as List).map((json) => CheckIn.fromJson(json)).toList();
  }

  // CREATE/UPDATE: Mencatat Check-In (Menggunakan Upsert)
  Future<void> logCheckIn(CheckIn checkIn) async {
    await _client.from('checkins').upsert(
      checkIn.toJson(), 
      onConflict: 'habit_id, check_in_date'
    );
  }
  
  // UPDATE Check-In
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
  
  // UPDATE Habit
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
  
  // =======================================================
  // [BARU DITAMBAHKAN] FUNGSI UNTUK GRAFIK MINGGUAN
  // =======================================================
  Future<List<CheckIn>> getCheckInsInDateRange(
      DateTime startDate, DateTime endDate, List<int> habitIds) async {
    
    // Format tanggal menjadi string YYYY-MM-DD
    // Supabase menggunakan format ISO, tapi memfilter hanya berdasarkan tanggal lebih bersih
    final startIso = startDate.toIso8601String().split('T')[0];
    final endIso = endDate.toIso8601String().split('T')[0];
    
    final response = await _client
        .from('checkins') // Menggunakan nama tabel 'checkins' sesuai kode Anda
        .select('*')
        .inFilter('habit_id', habitIds) 
        // Filter tanggal: check_in_date >= startDate
        .gte('check_in_date', startIso) 
        // Filter tanggal: check_in_date <= endDate
        .lte('check_in_date', endIso) 
        .order('check_in_date', ascending: false);
        
    return (response as List).map((map) => CheckIn.fromJson(map)).toList();
  }
}