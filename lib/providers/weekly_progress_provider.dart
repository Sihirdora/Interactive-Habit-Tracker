import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/check_in_model.dart';
import '../models/habit_model.dart';
import '../services/supabase_service.dart';
import 'habit_provider.dart'; // Untuk supabaseServiceProvider dan habitsProvider

// Definisi model DailySummary: {DateTime (tanggal bersih, 00:00:00): progressRate (0.0-1.0)}
typedef WeeklySummary = Map<DateTime, double>; 

final weeklyProgressProvider = FutureProvider<WeeklySummary>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final habitsAsync = ref.watch(habitsProvider);

  // Jika data habit belum dimuat, kembalikan map kosong
  if (!habitsAsync.hasValue) return {};

  final habits = habitsAsync.value!.where((h) => h.isActive).toList();
  if (habits.isEmpty) return {};

  // 1. Tentukan rentang 7 hari
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 6));

  // 2. Ambil semua Check-In untuk semua Habit aktif dalam 7 hari terakhir
  // CATATAN: Fungsi ini harus diimplementasikan di SupabaseService
  final List<CheckIn> allCheckIns = await service.getCheckInsInDateRange(
      sevenDaysAgo, today, habits.map((h) => h.id).toList());

  // 3. Struktur untuk menghitung total progress harian
  final dailyTotalProgress = <DateTime, double>{}; // {date: total_progress_percentage}
  final dailyHabitCount = <DateTime, int>{}; // {date: total_habit_active_count}

  // 4. Inisialisasi map untuk 7 hari dan hitung kontribusi setiap Check-In
  for (int i = 0; i < 7; i++) {
    final date = today.subtract(Duration(days: 6 - i));
    final cleanDate = DateTime(date.year, date.month, date.day);
    
    // Inisialisasi
    dailyTotalProgress[cleanDate] = 0.0;
    dailyHabitCount[cleanDate] = 0;

    // Filter check-in yang terjadi pada hari ini
    final relevantCheckIns = allCheckIns.where(
      (ci) => ci.checkInDate.year == cleanDate.year &&
              ci.checkInDate.month == cleanDate.month &&
              ci.checkInDate.day == cleanDate.day,
    ).toList();
    
    // Hitung Progress Rate untuk hari tersebut
    double totalProgressRate = 0.0;
    int habitCount = 0;

    for (final habit in habits) {
      // Dapatkan Check-In terakhir (paling relevan/total progress) untuk habit di hari tersebut
      final CheckIn? checkIn = relevantCheckIns.firstWhereOrNull(
          (ci) => ci.habitId == habit.id
      );

      if (checkIn != null) {
        double progressVal = checkIn.progressValue;
        double progressPercent = (habit.targetValue > 0)
            ? (progressVal / habit.targetValue).clamp(0.0, 1.0)
            : 0.0;
            
        totalProgressRate += progressPercent;
        habitCount++;
      }
    }
    
    dailyTotalProgress[cleanDate] = totalProgressRate;
    dailyHabitCount[cleanDate] = habitCount;
  }

  // 5. Hitung Rata-rata Harian (WeeklySummary)
  final weeklySummary = <DateTime, double>{};
  
  dailyTotalProgress.forEach((date, totalProgress) {
    final count = dailyHabitCount[date]!;
    // Rata-rata Progress (0.0 - 1.0)
    weeklySummary[date] = (count > 0) ? totalProgress / count : 0.0;
  });

  return weeklySummary;
});

// NOTE: Tambahkan ekstensi FirstWhereOrNull jika Anda belum memilikinya
extension IterableExtensions<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}