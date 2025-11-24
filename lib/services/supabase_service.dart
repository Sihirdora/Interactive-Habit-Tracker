// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_model.dart';
import '../models/check_in_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Operasi Kebiasaan (Habits) ---

  // READ: Stream untuk mendapatkan semua kebiasaan secara realtime
  Stream<List<Habit>> getHabitsStream() {
    // Diasumsikan RLS diaktifkan (policy only for auth.uid() is mandatory)
    return _client.from('habits')
        .stream(primaryKey: ['id'])
        .order('start_date', ascending: true)
        .map((maps) => maps.map((map) => Habit.fromJson(map)).toList());
  }

  // CREATE: Menambahkan kebiasaan baru
  Future<void> addHabit(Habit habit) async {
    await _client.from('habits').insert(habit.toJson());
  }
  
  // --- Operasi Check-In ---

  // READ: Mengambil riwayat check-in untuk kebiasaan tertentu
  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final response = await _client.from('checkins')
        .select()
        .eq('habit_id', habitId)
        .order('check_in_date', ascending: false);
    
    return (response as List).map((json) => CheckIn.fromJson(json)).toList();
  }

  // CREATE/UPDATE: Logika Check-In (Upsert)
  // Menggunakan upsert untuk memastikan hanya ada satu check-in per hari per kebiasaan
  Future<void> logCheckIn(CheckIn checkIn) async {
    await _client.from('checkins').upsert(checkIn.toJson(), onConflict: 'habit_id, check_in_date');
  }
}