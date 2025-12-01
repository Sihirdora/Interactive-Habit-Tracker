import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import 'journal_screen.dart';
import 'archive_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // 1. List Halaman untuk Bottom Navigation Bar
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    // Ganti HomeScreen dengan Widget Utama Anda
    const HomeScreen(), 
    const ReportScreen(),
    const JournalScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Menutup Drawer jika item dipilih dari Bottom Nav
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context); 
    }
  }

  // Widget untuk Side Menu (Drawer)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header Drawer
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Habit Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          
          // Menu Item: Dashboard (Navigasi ke index 0 Bottom Nav)
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context); // Tutup drawer
            },
          ),

          // Menu Item: Arsip Kebiasaan
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Arsip Kebiasaan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArchiveScreen()),
              );
            },
          ),
          
          // Menu Item: Pengaturan
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          
          const Divider(),

          // Menu Item: Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Tambahkan logika logout Anda di sini
              Navigator.pop(context); // Tutup drawer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda telah Logout.')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold akan menggunakan halaman yang dipilih (_screens[_selectedIndex])
    // dan menyediakan BottomNavigationBar serta Drawer.
    return Scaffold(
      // Body akan menampilkan halaman yang sedang aktif
      body: _screens[_selectedIndex], 
      
      // Side Menu (Drawer)
      drawer: _buildDrawer(context), 

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      
      // FAB (Floating Action Button) harus ada di MainWrapper
      // Tetapi karena HomeScreen yang ditampilkan, FAB harus dipindah ke sini
      // Jika FAB Anda ada di HomeScreen, Anda perlu memindahkannya ke MainWrapper 
      // dan membuatnya berfungsi dengan halaman yang sedang aktif.
      // Untuk demo, kita abaikan FAB, asumsikan FAB ada di HomeScreen.
      // Jika HomeScreen Anda adalah HomeScreen() di atas, pastikan ia tidak 
      // memiliki Scaffold dengan FAB sendiri.
    );
  }
}