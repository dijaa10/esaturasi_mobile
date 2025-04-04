import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:esaturasi/screen/pengumuman_screen.dart';
import 'package:esaturasi/screen/profile_screen.dart';

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  int _selectedIndex = 0; // Menyimpan index halaman aktif

  // Daftar halaman berdasarkan indeks
  final List<Widget> _pages = [
    HomeScreen(),
    PengumumanScreen(),
    ProfileScreen(),
  ];

  // Fungsi saat menu di-tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[
          _selectedIndex], // Menampilkan halaman sesuai index yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Menandai menu aktif
        onTap: _onItemTapped, // Panggil fungsi saat menu dipilih
        selectedItemColor: Colors.blue, // Warna saat aktif
        unselectedItemColor: Colors.grey, // Warna saat tidak aktif
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Artikel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
