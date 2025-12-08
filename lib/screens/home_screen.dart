// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../providers/checkin_provider.dart'; // [1] IMPORT BARU: CheckIn Provider
import '../models/check_in_model.dart';      // [1] IMPORT BARU: CheckIn Model
import 'add_habit_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mengambil data dari Provider (Real-time stream)
    final habitsAsync = ref.watch(habitsProvider);

    // Warna tema utama
    final Color backgroundColor = const Color(0xFF4C53A5);
    final Color cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tombol menu untuk membuka Drawer
        leading: Builder( 
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer(); 
            },
          ),
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
                    
                    // [2] MENGAMBIL PROGRESS HARIAN (currentVal)
                    // Kita asumsikan CheckIn yang pertama adalah progress harian hari ini
                    final currentCheckInsAsync = ref.watch(checkInsByHabitIdProvider(habit.id));
                    
                    // Default values jika data belum siap
                    double currentVal = 0.0;
                    double progressPercent = 0.0;
                    
                    if (currentCheckInsAsync.hasValue && currentCheckInsAsync.value!.isNotEmpty) {
                        final todayCheckIn = currentCheckInsAsync.value!
                            .firstWhere(
                                (ci) => ci.checkInDate.day == DateTime.now().day, 
                                orElse: () => CheckIn(id: 0, habitId: 0, checkInDate: DateTime.now(), progressValue: 0.0, isCompleted: false)
                            );
                        currentVal = todayCheckIn.progressValue;
                        progressPercent = currentVal / habit.targetValue;
                        if (progressPercent.isNaN || progressPercent.isInfinite) progressPercent = 0.0;
                        progressPercent = progressPercent.clamp(0.0, 1.0);
                    }

                    return GestureDetector(
                      onLongPress: () {
                        // Navigasi ke detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailScreen(habit: habit)),
                        );
                      },
                      // Navigasi ke detail saat diklik juga
                      onTap: () {
                        // AKSI: Menambah progress saat diklik
                        final notifier = ref.read(checkInNotifierProvider.notifier); // Panggil CheckIn Notifier

                        double progressToAdd;
                        if (habit.targetType == 'BOOLEAN') {
                          // Toggle: Jika sudah selesai (currentVal >= targetValue), progressToAdd menjadi negatif untuk reset.
                          progressToAdd = currentVal >= habit.targetValue 
                              ? -currentVal // Reset ke 0
                              : habit.targetValue - currentVal; // Lengkapi ke target
                        } else {
                          progressToAdd = 1.0; 
                        }
                        
                        // Cek: Hanya izinkan penambahan jika belum selesai (untuk COUNT/DURATION)
                        // BOOLEAN: selalu izinkan (untuk toggle)
                        if (habit.targetType == 'BOOLEAN' || currentVal < habit.targetValue) {
                           // [3] MEMANGGIL FUNGSI YANG BENAR
                           notifier.performCheckIn(
                              habit: habit, 
                              progressValue: currentVal + progressToAdd,
                           );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              // [4] PERBAIKAN: Mengganti withOpacity
                              color: Colors.black.withAlpha(25), 
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
                                      const SizedBox(
                                        width: 80, height: 80,
                                        child: CircularProgressIndicator(
                                          value: 1.0,
                                          strokeWidth: 8,
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      // PROGRESS CIRCLE (DATA REAL/MOCK)
                                      SizedBox(
                                        width: 80, height: 80,
                                        child: CircularProgressIndicator(
                                          value: progressPercent, // Menggunakan nilai yang dihitung dari CheckIn
                                          strokeWidth: 8,
                                          color: Color(habit.colorCode),
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
      // Tombol FAB dipindahkan ke sini untuk menambah Habit
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
    
    // Logika Icon Sederhana
    if (lowerName.contains('water') || lowerName.contains('minum air')) {
      iconData = Icons.local_drink;
    } else if (lowerName.contains('youtube') || lowerName.contains('nonton')) {
      iconData = Icons.ondemand_video;
    } else if (lowerName.contains('walk') || lowerName.contains('run') || lowerName.contains('lari')) {
      iconData = Icons.directions_run;
    } else {
      iconData = Icons.star; // Icon default
    }
    return Icon(iconData, size: 28, color: Color(colorCode));
  }
}