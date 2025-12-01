// lib/screens/edit_habit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

const List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class EditHabitScreen extends ConsumerStatefulWidget {
  final Habit habit;
  const EditHabitScreen({required this.habit, super.key});

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- Variabel State Form (Diinisialisasi dengan data Habit) ---
  late String _name;
  late String? _description;
  late String _targetType;
  late double _targetValue;
  late String? _unit;
  late Set<int> _selectedDays; 
  late Color _selectedColor;
  bool _isLoading = false;
  
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;

    // Inisialisasi State dengan Data Habit
    _name = habit.name;
    _description = habit.description;
    _targetType = habit.targetType;
    _targetValue = habit.targetValue;
    _unit = habit.unit;
    _selectedDays = Set<int>.from(habit.frequency);
    _selectedColor = Color(habit.colorCode);

    _targetController = TextEditingController(text: habit.targetValue.toString());
    _unitController = TextEditingController(text: habit.unit);

    _targetController.addListener(_updateTargetValue);
    _unitController.addListener(_updateUnit);
  }

  // --- (update methods dan dispose tetap sama) ---
  void _updateTargetValue() {
    final value = double.tryParse(_targetController.text);
    if (value != null) {
      _targetValue = value;
    }
  }

  void _updateUnit() {
    _unit = _unitController.text.isNotEmpty ? _unitController.text : null;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // --- Fungsi UPDATE Habit ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDays.isEmpty) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day for frequency.')),
        );
      }
      return;
    }

    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(habitsProvider.notifier);
      
      // Buat objek Habit BARU, tetapi pertahankan ID aslinya!
      final updatedHabit = Habit(
        id: widget.habit.id, // Kunci utama HARUS dipertahankan
        name: _name,
        description: _description,
        startDate: widget.habit.startDate, // Pertahankan tanggal mulai
        targetType: _targetType,
        targetValue: _targetValue,
        unit: _targetType == 'BOOLEAN' ? null : _unit, 
        frequency: _selectedDays.toList(), 
        isActive: widget.habit.isActive, 
        colorCode: _selectedColor.value, 
      );

      // Kirim data UPDATE ke Supabase
      await notifier.updateHabit(updatedHabit);
      
      // Tutup layar Edit dan Detail (kembali ke Dashboard)
      if (mounted) {
        // Pop dua kali: (1) Tutup EditScreen, (2) Tutup DetailScreen
        int count = 0;
        Navigator.popUntil(context, (route) {
          return count++ == 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update habit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleDay(int index) {
    setState(() {
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
      }
    });
  }

  // --- (Bagian Build Form sama dengan AddHabitScreen) ---
  @override
  Widget build(BuildContext context) {
    // ... (Kode Form Build sama persis dengan AddHabitScreen, tetapi panggil _submitForm)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Habit'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      // ... (Gunakan body dari AddHabitScreen.dart)
      body: _buildFormBody(context), // Menggunakan method untuk body
    );
  }

  // Pisahkan body form ke method untuk menghindari pengulangan kode penuh
  Widget _buildFormBody(BuildContext context) {
    // Ini adalah Body dari AddHabitScreen Anda. Pastikan Anda menyalinnya 
    // di sini atau menggunakannya sebagai fungsi terpisah yang dipanggil.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [Nama Kebiasaan]
            TextFormField(
              initialValue: _name, // Menggunakan initialValue
              decoration: const InputDecoration(labelText: 'Habit Name', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name.' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 20),
            // [Deskripsi]
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
              maxLines: 2,
              onSaved: (value) => _description = value,
            ),
            const SizedBox(height: 20),
            Text('Target Configuration', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // [Row Target] (Gunakan logika yang diperbaiki dari AddHabitScreen)
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded( 
                    flex: 3, 
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      value: _targetType,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _targetType = newValue);
                          // Reset controller jika BOOLEAN
                          if (newValue == 'BOOLEAN') {
                             _targetController.text = '1.0';
                             _unitController.clear();
                          }
                        }
                      },
                      items: <String>['COUNT', 'DURATION', 'BOOLEAN'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  if (_targetType != 'BOOLEAN')
                    Expanded(
                      flex: 3, 
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                        validator: (value) => (_targetType != 'BOOLEAN' && (value == null || double.tryParse(value) == null || double.parse(value) <= 0)) ? 'Required' : null,
                      ),
                    ),
                  const SizedBox(width: 8),

                  if (_targetType != 'BOOLEAN')
                    Expanded(
                      flex: 2, 
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit (e.g., min)', border: OutlineInputBorder()),
                        onSaved: (value) => _unit = value,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            
            // [Frequency]
            Text('Frequency (Days of the Week)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap( 
              spacing: 6.0, 
              runSpacing: 4.0, 
              children: List.generate(7, (index) {
                return ChoiceChip(
                  label: Text(weekdays[index]),
                  selected: _selectedDays.contains(index),
                  onSelected: (_) => _toggleDay(index),
                  selectedColor: _selectedColor.withAlpha((255 * 0.7).round()),
                  backgroundColor: Colors.grey.shade200,
                );
              }),
            ),
            const SizedBox(height: 20),
            
            // [Color Picker]
            Text('Habit Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (var color in [Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange, Colors.teal, Colors.pink])
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Tombol Delete di bawah
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('DELETE HABIT', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI DELETE HABIT ---
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kebiasaan?'),
        content: Text('Ini akan menghapus seluruh log dan riwayat untuk "${widget.habit.name}". Yakin ingin melanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(habitsProvider.notifier);
      await notifier.deleteHabit(widget.habit.id);
      
      // Kembali ke Dashboard setelah penghapusan
      if (mounted) {
        // Pop dua kali: (1) Tutup EditScreen, (2) Tutup DetailScreen
        int count = 0;
        Navigator.popUntil(context, (route) {
          return count++ == 2;
        });
      }
    }
  }
}