import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry_model.dart'; // Memastikan model diimport

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  // --- DELETE LOGIC ---
  Future<void> _handleDelete(BuildContext context, WidgetRef ref, JournalEntry entry) async {
    final journalNotifier = ref.read(journalProvider.notifier);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus entri "${entry.title ?? 'Refleksi Harian'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await journalNotifier.deleteEntry(entry.id);
    }
  }

  // --- UPDATE LOGIC (Dialog) ---
  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, JournalEntry entry) async {
    final titleController = TextEditingController(text: entry.title);
    final contentController = TextEditingController(text: entry.content);
    final journalNotifier = ref.read(journalProvider.notifier);

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Entri Jurnal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul (Opsional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Isi Jurnal'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Hanya menyimpan jika konten tidak kosong
                if (contentController.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Membuat objek baru menggunakan copyWith untuk mempertahankan ID dan tanggal
      final updatedEntry = entry.copyWith(
        title: titleController.text.isEmpty ? null : titleController.text,
        content: contentController.text,
      );
      await journalNotifier.updateEntry(updatedEntry);
    }
  }

  // --- UI TRIGGERS (Menu Bottom Sheet) ---
  void _showEditDeleteMenu(BuildContext context, WidgetRef ref, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Menggunakan children, bukan actions (FIX ERROR)
            mainAxisSize: MainAxisSize.min,
            children: [ // Menggunakan children (FIX ERROR)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Entri'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref, entry); // Panggil dialog Edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Entri', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDelete(context, ref, entry); // Panggil fungsi Hapus
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- CREATE LOGIC (Dialog) ---
  Future<void> _showAddJournalDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final journalNotifier = ref.read(journalProvider.notifier);

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Buat Entri Jurnal Baru'),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [ // Menggunakan children (FIX ERROR)
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Judul (Opsional)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Isi Jurnal'),
                  ),
                ],
              ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newEntry = JournalEntry(
        id: 0,
        entryDate: DateTime.now(),
        title: titleController.text.isEmpty ? null : titleController.text,
        content: contentController.text,
        moodRating: null, 
        relatedHabitId: null,
      );
      await journalNotifier.addEntry(newEntry);
    }
  }


  // --- WIDGET BUILD UTAMA (READ) ---
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalEntriesAsync = ref.watch(journalProvider); 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Harian'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: journalEntriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('Belum ada entri jurnal. Buat satu sekarang!'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: Text(entry.title ?? 'Refleksi Harian'),
                subtitle: Text('Tanggal: ${entry.entryDate.toString().substring(0, 10)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showEditDeleteMenu(context, ref, entry), // Trigger Menu
                ),
                onTap: () => _showEditDeleteMenu(context, ref, entry), // Trigger Menu
              );
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () => _showAddJournalDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}