// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import 'add_habit_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengambil data dari Provider (Real-time stream)
    final habitsAsync = ref.watch(habitsProvider);

    // Warna tema utama (Royal Blue/Purple)
    final Color backgroundColor = const Color(0xFF4C53A5);
    final Color cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER & DYNAMIC DATE SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- BAGIAN TANGGAL REAL-TIME ---
                SizedBox(
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Generate 5 hari ke depan dimulai dari hari ini
                      ...List.generate(5, (index) {
                        DateTime date = DateTime.now().add(Duration(days: index));
                        bool isActive = index == 0; // Hari ini aktif
                        return _buildRealTimeDateItem(date, isActive);
                      }),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
                      ),
                    ],
                  ),
                ),
                // --------------------------------
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. GRID CONTENT SECTION
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.white))),
              data: (habits) {
                if (habits.isEmpty) {
                  return const Center(
                    child: Text(
                      'No habits yet. Click + to add one!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];

                    // --- LOGIKA REAL-TIME UI ---
                    
                    // 1. Dapatkan Tanggal Hari Ini (Format String YYYY-MM-DD)
                    String todayKey = DateTime.now().toString().split(' ')[0];

                    // 2. Ambil nilai progress hari ini dari Model (Real-time data)
                    // Jika belum ada data hari ini, anggap 0.0
                    double currentVal = habit.dailyProgress[todayKey] ?? 0.0;

                    // 3. Hitung Persentase (0.0 sampai 1.0)
                    double progressRaw = (habit.targetValue > 0) 
                        ? (currentVal / habit.targetValue) 
                        : 0.0;

                    // Clamp agar visual lingkaran tidak error jika progress > 100%
                    double progressPercent = progressRaw.clamp(0.0, 1.0);

                    return GestureDetector(
                      onTap: () {
                        // AKSI: Menambah progress saat diklik
                        // Jika tipe BOOLEAN (Checklist), set ke full target
                        // Jika tipe COUNT/DURATION, tambah 1 unit
                        double incrementAmount = (habit.targetType == 'BOOLEAN') 
                            ? (habit.targetValue - currentVal) // Toggle logic sederhana: isi penuh
                            : 1.0; 
                        
                        // Panggil fungsi di Provider
                        if (currentVal < habit.targetValue || habit.targetType != 'BOOLEAN') {
                           ref.read(habitsProvider.notifier)
                              .incrementProgress(habit.id, incrementAmount);
                        }
                      },
                      onLongPress: () {
                        // Navigasi ke detail jika ingin melihat info lebih lengkap
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailScreen(habit: habit)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Track Circle (Background Abu)
                                      SizedBox(
                                        width: 80, height: 80,
                                        child: CircularProgressIndicator(
                                          value: 1.0,
                                          strokeWidth: 8,
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      // PROGRESS CIRCLE (DATA REAL)
                                      SizedBox(
                                        width: 80, height: 80,
                                        child: CircularProgressIndicator(
                                          value: progressPercent, 
                                          strokeWidth: 8,
                                          color: Color(habit.colorCode).withOpacity(1.0),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      // Icon Habit
                                      _getIconForHabit(habit.name, habit.colorCode),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Nama Habit
                              Text(
                                habit.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: backgroundColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              // Teks Persentase Real-time
                              Text(
                                "${(progressPercent * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddHabitScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF8B93FF),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildRealTimeDateItem(DateTime date, bool isActive) {
    const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = weekDays[date.weekday - 1];
    String dayNumber = date.day.toString();

    return Container(
      width: 50,
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFF8B93FF),
              borderRadius: BorderRadius.circular(15),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dayNumber,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForHabit(String name, int colorCode) {
    IconData iconData;
    String lowerName = name.toLowerCase();
    if (lowerName.contains('water') || lowerName.contains('drink')) {
      iconData = Icons.local_drink;
    } else if (lowerName.contains('cycle') || lowerName.contains('bike')) {
      iconData = Icons.directions_bike;
    } else if (lowerName.contains('walk') || lowerName.contains('run')) {
      iconData = Icons.directions_run;
    } else {
      iconData = Icons.water_drop;
    }
    return Icon(iconData, size: 28, color: Color(colorCode));
  }
}