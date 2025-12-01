// lib/screens/detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../models/habit_model.dart';
import '../models/check_in_model.dart'; 
import '../providers/checkin_provider.dart';
import 'edit_habit_screen.dart'; // Tambahkan untuk navigasi Edit

// --- FUNGSI TOP-LEVEL (HELPER) ---
double _daysBetween(DateTime from, DateTime to) {
  from = DateTime(from.year, from.month, from.day);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).toDouble();
}

// --- FUNGSI CRUD LOG CHECKIN (PERLU DIHAPUS DARI KELAS DAN DILETAKKAN DI SINI) ---

Future<void> _handleDeleteCheckIn(BuildContext context, WidgetRef ref, CheckIn checkIn) async {
  final checkInNotifier = ref.read(checkInNotifierProvider.notifier);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus Log?'),
      content: Text('Yakin ingin menghapus log untuk tanggal ${checkIn.checkInDate.toString().substring(0, 10)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
      ],
    ),
  );

  if (confirm == true) {
    await checkInNotifier.deleteEntry(checkIn.id, checkIn.habitId); 
  }
}

Future<void> _showEditCheckInDialog(BuildContext context, WidgetRef ref, CheckIn oldCheckIn, Habit habit) async {
  final progressController = TextEditingController(text: oldCheckIn.progressValue.toString());
  final checkInNotifier = ref.read(checkInNotifierProvider.notifier);
  
  final result = await showDialog<double>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Ubah Progres (${habit.unit ?? 'Count'})'),
        content: TextField(
          controller: progressController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Berapa banyak yang sudah dilakukan?',
            suffixText: habit.unit, 
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(dialogContext).pop()),
          ElevatedButton(
            child: const Text('Update'),
            onPressed: () {
              final progress = double.tryParse(progressController.text);
              if (progress != null && progress >= 0) {
                Navigator.of(dialogContext).pop(progress);
              }
            },
          ),
        ],
      );
    },
  );

  if (result != null) {
    final updatedCheckIn = CheckIn(
      id: oldCheckIn.id,
      habitId: oldCheckIn.habitId,
      checkInDate: oldCheckIn.checkInDate,
      progressValue: result,
      isCompleted: result >= habit.targetValue, 
    );
    await checkInNotifier.updateEntry(updatedCheckIn);
  }
}

void _showCheckInActionMenu(BuildContext context, WidgetRef ref, CheckIn checkIn, Habit habit) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Ubah Progres'),
            onTap: () {
              Navigator.pop(context);
              // Tambahkan habit sebagai argumen di sini
              _showEditCheckInDialog(context, ref, checkIn, habit);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Hapus Log Ini', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleDeleteCheckIn(context, ref, checkIn);
            },
          ),
        ],
      );
    },
  );
}


// --- KELAS UTAMA ---
class DetailScreen extends ConsumerWidget {
  final Habit habit;
  
  const DetailScreen({required this.habit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInNotifier = ref.watch(checkInNotifierProvider.notifier);
    final checkInsAsync = ref.watch(checkInsByHabitIdProvider(habit.id));
    final primaryColor = Color(habit.colorCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditHabitScreen(habit: habit),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(habit, primaryColor),
              const SizedBox(height: 20),

              Text(
                'Progress 30 Days',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _buildProgressChart(context, checkInsAsync, primaryColor, habit), 
              const SizedBox(height: 30),

              _buildStreakAndStatus(checkInsAsync, primaryColor),
              const SizedBox(height: 30),

              _buildInteractiveCheckIn(context, habit, checkInNotifier),
              const SizedBox(height: 30),
              
              _buildCheckInHistory(context, ref, checkInsAsync, habit), 
            ],
          ),
        ),
      ),
    );
  }
  
  // --- BUILD METHODS (SEKARANG INSTANCE METHODS DARI KELAS) ---
  
  Widget _buildHeader(Habit habit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.description ?? "No description provided.",
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 10),
        Text(
          'Target: ${habit.targetValue} ${habit.unit ?? ''} (${habit.targetType})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProgressChart(BuildContext context, AsyncValue<List<CheckIn>> checkInsAsync, Color color, Habit habit) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 16, right: 16, left: 8, bottom: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: checkInsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: color)),
        error: (err, stack) => Center(child: Text("Error loading chart: $err", textAlign: TextAlign.center)),
        data: (checkIns) {
          if (checkIns.isEmpty) {
            return Center(child: Text("No progress recorded yet.", style: TextStyle(color: color)));
          }

          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          final filteredData = checkIns.where((ci) => ci.checkInDate.isAfter(thirtyDaysAgo)).toList();

          final earliestDate = filteredData.isNotEmpty 
              ? filteredData.last.checkInDate 
              : DateTime.now().subtract(const Duration(days: 29));
          
          List<BarChartGroupData> barGroups = [];
          for (var ci in filteredData) {
            final double xValue = _daysBetween(earliestDate, ci.checkInDate);
            final double yValue = ci.progressValue;

            barGroups.add(
              BarChartGroupData(
                x: xValue.toInt(),
                barRods: [
                  BarChartRodData(
                    toY: yValue,
                    color: ci.isCompleted ? color : color.withAlpha(100),
                    width: 8,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                  ),
                  BarChartRodData(
                    toY: habit.targetValue, 
                    color: color.withAlpha(50), 
                    width: 1,
                  )
                ],
              ),
            );
          }

          final maxY = habit.targetValue * 1.2;
          
          return BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles( 
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(), 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10)
                    ),
                    reservedSize: 30,
                  ),
                ),
                bottomTitles: AxisTitles( 
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = earliestDate.add(Duration(days: value.toInt()));
                      if (value.toInt() % 7 != 0 && value.toInt() != (DateTime.now().difference(earliestDate).inDays).toInt()) return Container(); 
                      
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        angle: -0.8, 
                        space: 4,
                        child: Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 35,
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rodIndex != 0) return null; 

                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)} ${habit.unit ?? ''}\n', 
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: rod.toY >= habit.targetValue ? 'SUCCESS' : 'Partial', 
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontSize: 10,
                          ),
                        ),
                      ]
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakAndStatus(AsyncValue checkInsAsync, Color color) {
    return checkInsAsync.when(
      loading: () => const Center(child: Text("Calculating streak...")),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (checkIns) {
        final currentStreak = 5; 
        final longestStreak = 8;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard("Current Streak", "$currentStreak Days", color),
            _buildStatCard("Longest Streak", "$longestStreak Days", color),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 150,
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCheckIn(
    BuildContext context, 
    Habit habit, 
    CheckInNotifier checkInNotifier
  ) {
    final isCheckedIn = false; 

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: isCheckedIn ? Colors.grey : Color(habit.colorCode),
      ),
      onPressed: isCheckedIn ? null : () async {
        if (habit.targetType != 'BOOLEAN') {
          // Panggilan ke fungsi top-level yang sudah didefinisikan
          await _showProgressDialog(context, habit, checkInNotifier); 
        } else {
          await checkInNotifier.performCheckIn( 
            habit: habit,
            progressValue: 1.0,
            notes: "Boolean check-in",
          );
        }
      },
      icon: Icon(isCheckedIn ? Icons.check_circle : Icons.add_task),
      label: const Text( // FIX: Menambahkan label yang hilang
        'Log Progress',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
  
  // Perbaiki: Panggil fungsi top-level
  Future<void> _showProgressDialog(BuildContext context, Habit habit, CheckInNotifier checkInNotifier) async {
    final TextEditingController progressController = TextEditingController();
    
    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Log Progress (${habit.unit ?? 'Count'})'),
          content: TextField(
            controller: progressController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'How much did you do?',
              suffixText: habit.unit, 
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(), 
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                final progress = double.tryParse(progressController.text);
                if (progress != null && progress >= 0) {
                  Navigator.of(dialogContext).pop(progress); 
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      await checkInNotifier.performCheckIn(
        habit: habit,
        progressValue: result,
      );
    }
  }

  // Perbaiki: Panggil fungsi top-level
  Widget _buildCheckInHistory(BuildContext context, WidgetRef ref, AsyncValue checkInsAsync, Habit habit) { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Log',
          style: Theme.of(context).textTheme.titleLarge, 
        ),
        checkInsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text('Error loading history: $err'),
          data: (checkIns) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkIns.length, 
              itemBuilder: (context, index) {
                final checkIn = checkIns[index] as CheckIn; 
                final isCompleted = checkIn.progressValue >= habit.targetValue; 
                
                return ListTile(
                  leading: Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                  title: Text(checkIn.checkInDate.toIso8601String().substring(0, 10)),
                  subtitle: Text('Progres: ${checkIn.progressValue} ${habit.unit ?? ''}'),
                  onTap: () => _showCheckInActionMenu(context, ref, checkIn, habit), // FIX: Menambahkan habit
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCheckInActionMenu(context, ref, checkIn, habit), // FIX: Menambahkan habit
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}