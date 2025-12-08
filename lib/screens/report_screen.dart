import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart'; // Import HabitProvider
import '../providers/today_progress_provider.dart'; // Import todayHabitProgressProvider & todaySummaryProvider
import '../providers/weekly_progress_provider.dart'; // Import weeklyProgressProvider
import '../models/habit_model.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil data gabungan Habit + Progress Hari Ini
    final todayProgressDataAsync = ref.watch(todayHabitProgressProvider);
    
    // 2. Ambil ringkasan statistik Hari Ini (totalCompleted, totalActive, overallRate)
    final todaySummary = ref.watch(todaySummaryProvider);
    
    // 3. Ambil data mingguan untuk Grafik
    final weeklyProgressAsync = ref.watch(weeklyProgressProvider);

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
      body: todayProgressDataAsync.when( // Menggunakan Provider untuk data harian
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (progressData) {
          final summary = todaySummary;
          
          final int totalActive = summary.totalActive;
          final int completedToday = summary.completed;
          final double overallRate = summary.overallRate;

          // --- 2. SIAPKAN DATA GRAFIK MINGGUAN ---
          List<BarChartGroupData> barGroups = [];
          
          if (weeklyProgressAsync.hasValue) {
            final weeklySummary = weeklyProgressAsync.value!;
            final now = DateTime.now();
            
            for (int i = 0; i < 7; i++) {
              // Iterasi dari 6 hari lalu (i=0) sampai Hari Ini (i=6)
              final date = now.subtract(Duration(days: 6 - i));
              final cleanDate = DateTime(date.year, date.month, date.day);
              
              // Nilai (0.0 - 1.0) dari provider
              double rate = weeklySummary[cleanDate] ?? 0.0; 
              
              // Nilai untuk Grafik (0 - 100)
              double dailyRate = rate * 100; 

              // Buat batang grafik
              barGroups.add(
                BarChartGroupData(
                  x: i, // Urutan 0..6
                  barRods: [
                    BarChartRodData(
                      toY: dailyRate,
                      color: (6 - i) == 0 // Cek apakah ini hari ini
                          ? const Color(0xFF4C53A5)
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
          }
          // ----------------------------------------


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
                
                // Gunakan BarGroups yang sudah dihitung dari weeklyProgressAsync
                _buildChartCard(barGroups), 

                const SizedBox(height: 24),

                // LIST: Detail Per Habit
                const Text("Today's Breakdown", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                
                // Ulangi data dari todayHabitProgressProvider
                ...progressData.map((data) {
                    return _buildHabitStatRow(data.habit, data.progressPercent);
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
                  // Menghitung tanggal 6 hari lalu (value=0) hingga Hari Ini (value=6)
                  DateTime d = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  
                  // D.weekday mengembalikan 1 (Senin) hingga 7 (Minggu)
                  // Kita perlu d.weekday - 1 untuk indeks list (0 hingga 6)
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