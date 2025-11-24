// lib/models/check_in_model.dart

class CheckIn {
  final int id;
  final int habitId;
  final DateTime checkInDate;
  final double progressValue;
  final bool isCompleted;
  final String? notes;

  CheckIn({
    required this.id,
    required this.habitId,
    required this.checkInDate,
    required this.progressValue,
    required this.isCompleted,
    this.notes,
  });

  /// Factory constructor untuk membuat objek CheckIn dari data JSON 
  /// yang diterima dari Supabase.
  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      // 'id' di Supabase adalah BIGSERIAL (int di Dart)
      id: json['id'] as int, 
      // Foreign Key
      habitId: json['habit_id'] as int, 
      // Konversi string tanggal dari DB ke DateTime
      checkInDate: DateTime.parse(json['check_in_date'] as String), 
      // progress_value adalah REAL/float8 di DB (num di JSON, diubah ke double)
      progressValue: (json['progress_value'] as num).toDouble(),
      isCompleted: json['is_completed'] as bool,
      notes: json['notes'] as String?,
    );
  }

  /// Metode untuk mengonversi objek CheckIn menjadi format JSON 
  /// yang siap dikirim ke Supabase untuk operasi INSERT atau UPDATE (UPSERT).
  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      // Format DATE (YYYY-MM-DD) yang dibutuhkan Supabase/PostgreSQL
      'check_in_date': checkInDate.toIso8601String().substring(0, 10), 
      'progress_value': progressValue,
      'is_completed': isCompleted,
      'notes': notes,
      // 'id' tidak perlu disertakan di sini jika Anda menggunakan INSERT/UPSERT
      // dan mengandalkan DB untuk menghasilkan ID baru, kecuali saat UPDATE spesifik.
    };
  }

  // Metode untuk membuat salinan data dengan perubahan (Berguna untuk State Management)
  CheckIn copyWith({
    int? id,
    int? habitId,
    DateTime? checkInDate,
    double? progressValue,
    bool? isCompleted,
    String? notes,
  }) {
    return CheckIn(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      checkInDate: checkInDate ?? this.checkInDate,
      progressValue: progressValue ?? this.progressValue,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}