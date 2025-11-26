class Habit {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final String targetType; // 'COUNT', 'DURATION', 'BOOLEAN'
  final double targetValue;
  final String? unit;
  final List<int> frequency;
  final bool isActive;
  final int colorCode;
  
  // FIELD BARU: Progress & Reminder
  final Map<String, double> dailyProgress; 
  final String? reminderTime; // Format "HH:mm"
  final bool isReminderActive;

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
    this.dailyProgress = const {}, 
    this.reminderTime,
    this.isReminderActive = false,
  });

  // METHOD INI YANG MENYEBABKAN ERROR SEBELUMNYA (Sekarang sudah diperbaiki)
  Habit copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? startDate,
    String? targetType,
    double? targetValue,
    String? unit,
    List<int>? frequency,
    bool? isActive,
    int? colorCode,
    Map<String, double>? dailyProgress,
    String? reminderTime,
    bool? isReminderActive,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      colorCode: colorCode ?? this.colorCode,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      // Update field baru
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderActive: isReminderActive ?? this.isReminderActive,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    // Parsing progress
    Map<String, double> parsedProgress = {};
    if (json['daily_progress'] != null) {
      (json['daily_progress'] as Map<String, dynamic>).forEach((key, value) {
        parsedProgress[key] = (value as num).toDouble();
      });
    }

    return Habit(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json.containsKey('description') ? json['description'] as String? : null,
      startDate: DateTime.parse(json['start_date'] as String),
      targetType: json['target_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      unit: json.containsKey('unit') ? json['unit'] as String? : null,
      frequency: List<int>.from(json['frequency']),
      isActive: json['is_active'] as bool? ?? true,
      colorCode: json['color_code'] as int,
      dailyProgress: parsedProgress,
      // Parsing Reminder dari Database
      reminderTime: json['reminder_time'] as String?,
      isReminderActive: json['is_reminder_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'target_type': targetType,
      'target_value': targetValue,
      'unit': unit,
      'frequency': frequency,
      'is_active': isActive,
      'color_code': colorCode,
      'daily_progress': dailyProgress,
      // Mengirim Reminder ke Database
      'reminder_time': reminderTime,
      'is_reminder_active': isReminderActive,
    };
  }
}