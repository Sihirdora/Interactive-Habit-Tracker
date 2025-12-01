// lib/models/journal_entry_model.dart

class JournalEntry {
  final int id;
  // final String userId; // Tambahkan ini jika Auth sudah aktif
  final DateTime entryDate;
  final String? title;
  final String content;
  final int? moodRating;
  final int? relatedHabitId;

  JournalEntry({
    required this.id,
    required this.entryDate,
    this.title,
    required this.content,
    this.moodRating,
    this.relatedHabitId,
  });

  // Factory constructor untuk menerima data dari Supabase (JSON)
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as int,
      entryDate: DateTime.parse(json['entry_date'] as String),
      title: json['title'] as String?,
      content: json['content'] as String,
      moodRating: json['mood_rating'] as int?,
      relatedHabitId: json['related_habit_id'] as int?,
    );
  }

  // Metode untuk mengirim data ke Supabase (JSON)
  Map<String, dynamic> toJson() {
    return {
      'entry_date': entryDate.toIso8601String().substring(0, 10),
      'title': title,
      'content': content,
      'mood_rating': moodRating,
      'related_habit_id': relatedHabitId,
    };
  }

  // --- FIX: Method copyWith ditambahkan untuk Update/Edit ---
  JournalEntry copyWith({
    int? id, 
    DateTime? entryDate, 
    String? title, 
    String? content, 
    int? moodRating, 
    int? relatedHabitId,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      content: content ?? this.content,
      moodRating: moodRating ?? this.moodRating,
      relatedHabitId: relatedHabitId ?? this.relatedHabitId,
    );
  }
}