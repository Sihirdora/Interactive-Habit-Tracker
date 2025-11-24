// lib/models/habit_model.dart

class Habit {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final String targetType;
  final double targetValue;
  final String? unit;
  final List<int> frequency;
  final bool isActive;
  final int colorCode;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.targetType,
    required this.targetValue,
    this.unit,
    required this.frequency,
    required this.isActive,
    required this.colorCode,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json.containsKey('description') ? json['description'] as String? : null, 
      startDate: DateTime.parse(json['start_date'] as String), 
      targetType: json['target_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      unit: json.containsKey('unit') ? json['unit'] as String? : null,
      frequency: List<int>.from(json['frequency']), 
      isActive: json['is_active'] as bool,
      colorCode: json['color_code'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'target_type': targetType,
      'target_value': targetValue,
      'unit': unit,
      'frequency': frequency,
      'is_active': isActive,
      'color_code': colorCode,
    };
  }
}