import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../models/habit_model.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Habit Activity',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4C53A5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Teks
                const Text(
                  "Consistency Graph",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "See your daily completion intensity.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- HEATMAP SECTION ---
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // Agar mulai dari kanan (hari ini)
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label Hari (Mon, Wed, Fri)
                          _buildDayLabels(),
                          
                          const SizedBox(width: 10),
                          
                          // Grid Kotak-kotak
                          _buildHeatmapGrid(habits),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- LEGEND (Keterangan Warna) ---
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Less ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    _buildLegendBox(Colors.grey.shade200),
                    _buildLegendBox(const Color(0xFF9BE9A8)), // Hijau Github Lv 1
                    _buildLegendBox(const Color(0xFF40C463)), // Lv 2
                    _buildLegendBox(const Color(0xFF30A14E)), // Lv 3
                    _buildLegendBox(const Color(0xFF216E39)), // Lv 4
                    const Text(" More", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDayLabels() {
    // Tinggi kotak + margin vertikal = 16 + 4 = 20
    // Kita atur posisi text agar sejajar dengan baris hari
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
        SizedBox(height: 24), // Spacer agar sejajar Senin (Index 1)
        Text("Mon", style: TextStyle(fontSize: 10, color: Colors.grey)),
        SizedBox(height: 26), // Spacer ke Wed (Index 3)
        Text("Wed", style: TextStyle(fontSize: 10, color: Colors.grey)),
        SizedBox(height: 26), // Spacer ke Fri (Index 5)
        Text("Fri", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHeatmapGrid(List<Habit> habits) {
    // Konfigurasi Grid
    const int totalWeeks = 18; // Menampilkan sekitar 4 bulan terakhir
    
    // Cari hari Minggu terakhir (Start of Week) untuk kolom terakhir (minggu ini)
    DateTime now = DateTime.now();
    // Geser ke hari Senin terdekat (atau biarkan jika ingin start Minggu)
    // Di sini kita pakai logika kolom = 1 minggu (Senin - Minggu)
    
    List<Widget> weekColumns = [];

    for (int w = 0; w < totalWeeks; w++) {
      // Mundur w minggu dari sekarang
      DateTime weekStart = now.subtract(Duration(days: (now.weekday - 1) + (w * 7)));
      
      List<Widget> daySquares = [];
      for (int d = 0; d < 7; d++) {
        // Senin = 0, Selasa = 1 ... Minggu = 6 (karena kita atur weekStart di senin)
        // Kita perlu menyesuaikan agar tanggal bergerak maju dalam minggu itu
        // weekStart sebenarnya adalah Senin minggu ini.
        // Jadi kita kurangi 'w' minggu, lalu di loop 'd' kita tambah hari.
        
        // Agar urutannya benar (Grid GitHub biasanya Kanan=Terbaru):
        // Kita generate dari minggu terlama ke minggu terbaru, 
        // TAPI karena SingleChildScrollView reversed=true, kita generate dari Terbaru (Kiri kode) ke Lama.
        
        // Revisi logika date:
        // Column 0 (paling kanan di layar) = Minggu ini
        DateTime date = now.subtract(Duration(days: (now.weekday - 1))).add(Duration(days: d)).subtract(Duration(days: w * 7));
        
        // Cek jika tanggal > hari ini (masa depan), jangan render kotak warna
        if (date.isAfter(now)) {
           daySquares.add(Container(
            width: 16, height: 16, 
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(2)),
           ));
           continue;
        }

        // Hitung Intensitas Warna
        Color color = _getColorForDate(date, habits);
        
        daySquares.add(
          Tooltip(
            message: "${date.year}-${date.month}-${date.day}",
            child: Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.all(2), // Jarak antar kotak
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }
      
      weekColumns.add(
        Column(
          children: daySquares,
        )
      );
    }

    return Row(
      children: weekColumns.reversed.toList(), // Balik agar minggu ini ada di paling kanan (karena reversed scroll)
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // --- LOGIKA WARNA (HEATMAP) ---
  
  Color _getColorForDate(DateTime date, List<Habit> habits) {
    String dateKey = date.toString().split(' ')[0]; // "YYYY-MM-DD"
    
    // 1. Hitung total target hari itu (Denominator)
    // Hanya hitung habit yang aktif dan hari tersebut termasuk dalam frekuensinya (opsional, disini kita hitung semua active)
    double totalPotential = 0;
    double totalAchieved = 0;

    for (var habit in habits) {
      if (!habit.isActive) continue;
      
      // Jika habit punya target (bukan 0)
      if (habit.targetValue > 0) {
        // Di sini kita asumsikan setiap habit bernilai "1 poin" jika completed, 
        // atau kita gunakan persentase pencapaian.
        // Agar adil, kita pakai rasio pencapaian (0.0 - 1.0)
        
        double current = habit.dailyProgress[dateKey] ?? 0.0;
        double ratio = (current / habit.targetValue).clamp(0.0, 1.0);
        
        totalAchieved += ratio;
        totalPotential += 1.0; // Max kontribusi habit ini adalah 1.0 (100%)
      }
    }

    // 2. Hitung Rata-rata Harian
    double dailyIntensity = (totalPotential > 0) 
        ? (totalAchieved / totalPotential) 
        : 0.0;

    // 3. Mapping ke Warna GitHub
    if (dailyIntensity == 0) return Colors.grey.shade200; // Kosong
    if (dailyIntensity <= 0.25) return const Color(0xFF9BE9A8); // Light Green
    if (dailyIntensity <= 0.50) return const Color(0xFF40C463); // Medium Green
    if (dailyIntensity <= 0.75) return const Color(0xFF30A14E); // Deep Green
    return const Color(0xFF216E39); // Darkest Green
  }
}