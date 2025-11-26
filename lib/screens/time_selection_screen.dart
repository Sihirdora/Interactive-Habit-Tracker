import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

class TimeSelectionScreen extends ConsumerStatefulWidget {
  final Habit draftHabit; // Data dari halaman sebelumnya

  const TimeSelectionScreen({super.key, required this.draftHabit});

  @override
  ConsumerState<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends ConsumerState<TimeSelectionScreen> {
  // Waktu default: 08:00
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isReminderActive = true;
  bool _isLoading = false;

  void _saveHabit() async {
    setState(() => _isLoading = true);
    
    // Format Waktu ke String "HH:mm" (Misal "08:30")
    final String timeString = 
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    // Gabungkan data lama + data waktu baru
    final finalHabit = widget.draftHabit.copyWith(
      reminderTime: timeString,
      isReminderActive: _isReminderActive,
    );

    try {
      // Simpan ke Supabase via Provider
      await ref.read(habitsProvider.notifier).addHabit(finalHabit);
      
      if (mounted) {
        // Kembali ke Home (tutup halaman add & time selection)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Schedule (2/2)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Icon Ilustrasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF92A3FD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm, size: 60, color: Color(0xFF92A3FD)),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Set a Reminder",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "When do you want to perform '${widget.draftHabit.name}'?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // 2. Time Picker (Gaya iOS/Cupertino sesuai gambar Selection)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2023, 1, 1, 8, 0),
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(newTime);
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            // 3. Switch Notifikasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        "Notify Me",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isReminderActive,
                    activeColor: const Color(0xFF92A3FD),
                    onChanged: (val) => setState(() => _isReminderActive = val),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 4. Tombol Finish
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _saveHabit,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Finish & Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}