// lib/services/journal_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry_model.dart';

class JournalService {
  final SupabaseClient _client = Supabase.instance.client;
  // TODO: Tambahkan final String? userId; jika Auth sudah aktif

  // READ: Mengambil semua entri jurnal
  Stream<List<JournalEntry>> getJournalEntriesStream() {
    return _client.from('journal_entries')
        .stream(primaryKey: ['id'])
        // Urutkan berdasarkan tanggal terbaru
        .order('entry_date', ascending: false) 
        .map((maps) => maps.map((map) => JournalEntry.fromJson(map)).toList());
  }

  // CREATE: Menambahkan entri baru
  Future<void> addJournalEntry(JournalEntry entry) async {
    // Note: Karena Anda belum mengimplementasikan Auth/user_id, kita hanya mengirim data entry
    await _client.from('journal_entries').insert(entry.toJson());
  }

  // UPDATE: Memperbarui entri
  Future<void> updateJournalEntry(JournalEntry entry) async {
    await _client.from('journal_entries')
        .update(entry.toJson())
        .eq('id', entry.id);
  }

  // DELETE: Menghapus entri
  Future<void> deleteJournalEntry(int entryId) async {
    await _client.from('journal_entries')
        .delete()
        .eq('id', entryId);
  }
}