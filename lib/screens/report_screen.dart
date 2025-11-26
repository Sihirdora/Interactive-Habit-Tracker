import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import '../models/habit_model.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil data habit dari Provider
    final habitsAsync = ref.watch(habitsProvider);
    final todayKey = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Background abu sangat muda
      appBar: AppBar(
        title: const Text(
          'Statistics & Report',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4C53A5), // Royal Blue
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No habit data yet.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // --- PERHITUNGAN STATISTIK ---
          
          // 1. Hitung performa hari ini
          int totalActive = habits.where((h) => h.isActive).length;
          int completedToday = 0;
          double totalProgressSum = 0;

          for (var habit in habits) {
            if (!habit.isActive) continue;
            double current = habit.dailyProgress[todayKey] ?? 0.0;
            
            // Cek status completed
            if (current >= habit.targetValue && habit.targetValue > 0) {
              completedToday++;
            }
            
            // Hitung persentase habit ini (max 1.0)
            double p = (habit.targetValue > 0) 
                ? (current / habit.targetValue) 
                : 0.0;
            totalProgressSum += p.clamp(0.0, 1.0);
          }

          // Rata-rata progress semua habit hari ini (0.0 - 1.0)
          double overallRate = (totalActive > 0) 
              ? (totalProgressSum / totalActive) 
              : 0.0;

          // 2. Siapkan data Grafik 7 Hari Terakhir
          List<BarChartGroupData> barGroups = [];
          for (int i = 6; i >= 0; i--) {
            DateTime date = DateTime.now().subtract(Duration(days: i));
            String key = date.toString().split(' ')[0];
            
            // Hitung rata-rata di hari tersebut
            double dailySum = 0;
            int count = 0;
            for (var habit in habits) {
               if (!habit.isActive) continue;
               double val = habit.dailyProgress[key] ?? 0.0;
               double p = (habit.targetValue > 0) ? (val / habit.targetValue) : 0.0;
               dailySum += p.clamp(0.0, 1.0);
               count++;
            }
            double dailyRate = (count > 0) ? (dailySum / count) * 100 : 0.0;

            // Buat batang grafik
            barGroups.add(
              BarChartGroupData(
                x: 6 - i, // Urutan 0..6
                barRods: [
                  BarChartRodData(
                    toY: dailyRate,
                    color: i == 0 
                        ? const Color(0xFF4C53A5) // Hari ini warnanya beda
                        : const Color(0xFFB0C4DE),
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100, // Background penuh 100%
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            );
          }

          // --- UI BUILDER ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD 1: Ringkasan Hari Ini
                _buildSummaryCard(completedToday, totalActive, overallRate),
                
                const SizedBox(height: 24),
                
                // CARD 2: Grafik Mingguan
                const Text("Consistency (Last 7 Days)", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                _buildChartCard(barGroups),

                const SizedBox(height: 24),

                // LIST: Detail Per Habit
                const Text("Today's Breakdown", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                
                // Tampilkan list habit beserta progress bar-nya
                ...habits.where((h) => h.isActive).map((habit) {
                   double current = habit.dailyProgress[todayKey] ?? 0.0;
                   double p = (habit.targetValue > 0) ? (current / habit.targetValue) : 0.0;
                   return _buildHabitStatRow(habit, p.clamp(0.0, 1.0));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSummaryCard(int completed, int total, double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C53A5), Color(0xFF7B81D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Overall Progress", 
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text("${(rate * 100).toInt()}%", 
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("You completed $completed out of $total habits today.", 
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  backgroundColor: Colors.white24,
                ),
                Icon(
                  rate >= 1.0 ? Icons.emoji_events : Icons.trending_up, 
                  color: Colors.white, size: 30
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartCard(List<BarChartGroupData> barGroups) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: 100,
          barGroups: barGroups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hilangkan angka Y axis agar bersih
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Label hari (misal: Mon, Tue)
                  DateTime d = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[d.weekday - 1],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitStatRow(Habit habit, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(habit.name, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${(progress * 100).toInt()}%", 
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Color(habit.colorCode), // Warna sesuai habit
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}