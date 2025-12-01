// lib/providers/journal_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry_model.dart';
import '../services/journal_service.dart';

// Provider untuk JournalService
// Asumsi JournalService sudah terdefinisi dan diinisialisasi
final journalServiceProvider = Provider((ref) => JournalService());

// StateNotifier untuk mengelola daftar entri jurnal
class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final JournalService _service;
  
  JournalNotifier(this._service) : super(const AsyncValue.loading()) {
    _fetchEntries();
  }

  void _fetchEntries() {
    // Listen ke stream Supabase untuk update realtime
    _service.getJournalEntriesStream().listen(
      (entries) {
        state = AsyncValue.data(entries);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  // CREATE
  Future<void> addEntry(JournalEntry entry) async {
    // Panggil service; Stream Supabase akan otomatis memicu refresh state
    await _service.addJournalEntry(entry);
  }

  // --- RUD: UPDATE (Baru Ditambahkan) ---
  Future<void> updateEntry(JournalEntry entry) async {
    // Panggil service; Stream Supabase akan otomatis memicu refresh state
    await _service.updateJournalEntry(entry);
  }

  // --- RUD: DELETE (Baru Ditambahkan) ---
  Future<void> deleteEntry(int entryId) async {
    // Panggil service; Stream Supabase akan otomatis memicu refresh state
    await _service.deleteJournalEntry(entryId);
  }
}

// Global Provider untuk diakses di UI
final journalProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>(
  (ref) {
    final service = ref.watch(journalServiceProvider);
    return JournalNotifier(service);
  },
);