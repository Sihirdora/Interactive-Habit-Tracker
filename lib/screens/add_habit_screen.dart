// lib/screens/add_habit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

const List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Variabel State Form
  String _name = '';
  String? _description;
  String _targetType = 'COUNT'; 
  double _targetValue = 1.0;
  String? _unit;
  
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; 
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;
  
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
      
      final newHabit = Habit(
        id: 0, 
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

      await notifier.addHabit(newHabit);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add habit: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Read for 30 minutes',
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name.' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Why do you want to start this habit?',
                ),
                maxLines: 2,
                onSaved: (value) => _description = value,
              ),
              const SizedBox(height: 20),
              Text('Target Configuration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              // --- FIX 1: Menggunakan Flex untuk Target Configuration (Anti-Overflow) ---
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
                          setState(() {
                            _targetType = newValue;
                            if (newValue == 'BOOLEAN') {
                               _targetController.text = '1.0';
                               _unitController.clear();
                            }
                          });
                        }
                      },
                      items: <String>['COUNT', 'DURATION', 'BOOLEAN']
                          .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
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
              
              Text('Frequency (Days of the Week)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              
              // --- FIX 2: Menggunakan Wrap untuk Frequency (Anti-Overflow) ---
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
            ],
          ),
        ),
      ),
    );
  }
}