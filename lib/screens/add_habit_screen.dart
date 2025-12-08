import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart'; // Pastikan import model Anda
import 'time_selection_screen.dart'; // Import halaman baru (Jika ada)

const List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String? _description;
  String _targetType = 'COUNT';
  double _targetValue = 1.0;
  String? _unit;

  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  Color _selectedColor = Colors.blue;
  
  // Controller
  final TextEditingController _targetController = TextEditingController(text: '1.0');
  final TextEditingController _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetController.addListener(_updateTargetValue);
    _unitController.addListener(_updateUnit);
  }

  void _updateTargetValue() {
    final value = double.tryParse(_targetController.text);
    if (value != null) _targetValue = value;
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

  void _goToNextStep() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    _formKey.currentState!.save();

    // Buat objek Habit SEMENTARA (belum disimpan ke DB)
    final tempHabit = Habit(
      id: 0, // ID sementara
      name: _name,
      description: _description,
      startDate: DateTime.now(),
      targetType: _targetType,
      targetValue: _targetValue,
      unit: _targetType == 'BOOLEAN' ? null : _unit,
      frequency: _selectedDays.toList(),
      isActive: true,
      colorCode: _selectedColor.value,
    );

    // Pindah ke Halaman Waktu (Step 2)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSelectionScreen(draftHabit: tempHabit),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Habit (1/2)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INPUT NAMA
              Text("What do you want to do?", style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 5),
              TextFormField(
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'e.g., Morning Yoga',
                  border: InputBorder.none,
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const Divider(thickness: 1.5),
              const SizedBox(height: 20),

              // 2. INPUT DESKRIPSI
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Description (Optional)',
                    border: InputBorder.none, // Hapus border bawaan TextFormField
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    prefixIcon: Icon(Icons.notes, color: Colors.grey),
                  ),
                  onSaved: (val) => _description = val,
                ),
              ),
              const SizedBox(height: 20),

              // 3. TARGET & UNIT
              const Text('Target Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                    Expanded(
                    // Perbaikan: flex 2 (untuk 'COUNT/DURATION/BOOLEAN')
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(), 
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                      ),
                      value: _targetType,
                      items: ['COUNT', 'DURATION', 'BOOLEAN'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() {
                        _targetType = v!;
                        if(v == 'BOOLEAN') { 
                            _targetController.text = '1.0'; 
                            _unitController.clear(); 
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if(_targetType != 'BOOLEAN') ...[
                    Expanded(
                      // Perbaikan: flex 3 (sebelumnya 2)
                      flex: 3, 
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // Perbaikan: flex 3 (sebelumnya 2)
                      flex: 3, 
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      ),
                    ),
                  ]
                ],
              ),
              
              const SizedBox(height: 25),

              // 4. FREKUENSI
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  bool isSelected = _selectedDays.contains(index);
                  return ChoiceChip(
                    label: Text(weekdays[index]),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(index),
                    selectedColor: _selectedColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? _selectedColor : Colors.black),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: isSelected ? _selectedColor : Colors.transparent),
                  );
                }),
              ),
              
              const SizedBox(height: 25),

              // 5. WARNA
              const Text('Color Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [Colors.blue, Colors.red, Colors.orange, Colors.purple, Colors.green, Colors.teal].map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 16,
                      child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // TOMBOL NEXT
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF92A3FD), // Warna biru muda sesuai tema
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _goToNextStep,
                  child: const Text("Next Step", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}