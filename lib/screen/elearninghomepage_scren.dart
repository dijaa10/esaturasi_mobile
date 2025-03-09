import 'package:flutter/material.dart';
import 'homepage_screen.dart';
import 'mapelpage_screen.dart';
import 'tugaspage_screen.dart';
import 'profilepage_screen.dart';

class ELearningHomePage extends StatefulWidget {
  @override
  State<ELearningHomePage> createState() => _ELearningHomePageState();
}

class _ELearningHomePageState extends State<ELearningHomePage> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan berdasarkan index
  final List<Widget> _pages = [
    HomePage(),
    MapelPage(),
    TugasSiswaPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Mapel'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
