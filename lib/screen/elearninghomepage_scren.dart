import 'package:flutter/material.dart';
import 'homepage_screen.dart';
import 'mapelpage_screen.dart';
import 'tugaspage_screen.dart';
import 'profile_screen.dart';

class ELearningHomePage extends StatefulWidget {
  @override
  State<ELearningHomePage> createState() => _ELearningHomePageState();
}

class _ELearningHomePageState extends State<ELearningHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  // Colors for the elegant design
  final Color _primaryColor = Color(0xFF1976D2);
  final Color _accentColor = Color(0xFF64B5F6);
  final Color _unselectedColor = Color(0xFF9E9E9E);

  // Daftar halaman yang akan ditampilkan berdasarkan index
  final List<Widget> _pages = [
    HomePage(),
    MapelPage(),
    TugasSiswaPage(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedIndex = index;
      });
      // Trigger animation
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Disable swiping
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: _primaryColor,
            unselectedItemColor: _unselectedColor,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 11,
            ),
            onTap: _onItemTapped,
            items: [
              _buildNavItem(Icons.dashboard, 'Beranda', 0),
              _buildNavItem(Icons.book, 'Jadwal', 1),
              _buildNavItem(Icons.assignment, 'Tugas', 2),
              _buildNavItem(Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedIndex == index
                  ? _accentColor.withOpacity(_animationController.value * 0.2)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: _selectedIndex == index ? 26 : 24,
            ),
          );
        },
      ),
      activeIcon: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 300),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 1.0 + (0.2 * value),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withOpacity(0.2),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 26,
              ),
            ),
          );
        },
      ),
      label: label,
    );
  }
}
