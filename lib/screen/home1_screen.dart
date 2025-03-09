import 'package:flutter/material.dart';

class ELearningHomePage extends StatefulWidget {
  const ELearningHomePage({Key? key}) : super(key: key);

  @override
  State<ELearningHomePage> createState() => _ELearningHomePageState();
}

class _ELearningHomePageState extends State<ELearningHomePage> {
  int _selectedIndex = 0;
  final String _studentName = "Budi Santoso";
  final String _studentClass = "XII RPL 2";
  final String _avatarUrl = "https://via.placeholder.com/150";

  final List<Map<String, dynamic>> _courses = [
    {
      'title': 'Pemrograman Web',
      'teacher': 'Pak Andi Wijaya',
      'progress': 0.75,
      'color': Colors.blue,
      'icon': Icons.computer,
    },
    {
      'title': 'Basis Data',
      'teacher': 'Ibu Siti Aminah',
      'progress': 0.6,
      'color': Colors.orange,
      'icon': Icons.storage,
    },
    {
      'title': 'Pemrograman Mobile',
      'teacher': 'Pak Dedi Kurniawan',
      'progress': 0.85,
      'color': Colors.green,
      'icon': Icons.phone_android,
    },
    {
      'title': 'Desain Grafis',
      'teacher': 'Ibu Ratna Dewi',
      'progress': 0.45,
      'color': Colors.purple,
      'icon': Icons.brush,
    },
  ];

  final List<Map<String, dynamic>> _assignments = [
    {
      'title': 'Membuat Web Portfolio',
      'course': 'Pemrograman Web',
      'deadline': 'Hari ini, 14:00',
      'isUrgent': true,
    },
    {
      'title': 'Membuat ERD Database Perpustakaan',
      'course': 'Basis Data',
      'deadline': 'Besok, 10:00',
      'isUrgent': false,
    },
  ];

  final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Jadwal Ujian Praktikum',
      'content':
          'Ujian praktikum akan dilaksanakan pada tanggal 15-20 Maret 2025.',
      'date': '5 Maret 2025',
    },
  ];

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi,';
    if (hour < 17) return 'Selamat Siang,';
    return 'Selamat Malam,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'E-Learning SMK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // Warna teks agar kontras
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 28),
            onPressed: () {
              // Tambahkan navigasi ke halaman notifikasi
            },
          ),
          const SizedBox(width: 12),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)], // Gradasi biru
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4, // Tambahkan efek shadow agar lebih elegan
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with welcome message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(_avatarUrl),
                        backgroundColor: Colors.white,
                        // Tambahkan border ke avatar
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[100],
                              ),
                            ),
                            Text(
                              _studentName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _studentClass,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ringkasan Aktivitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActivityCard(Icons.assignment, '3',
                          'Tugas Tertunda', Colors.orange),
                      _buildActivityCard(
                          Icons.book, '4', 'Tugas Terlambat', Colors.green),
                      _buildActivityCard(
                          Icons.quiz, '2', 'Ujian Mendatang', Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            // My Courses Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jadwal Hari Ini',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lihat Semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        return _buildCourseCard(_courses[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Assignments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tugas Tertunda',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lihat Semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      return _buildAssignmentCard(_assignments[index]);
                    },
                  ),

                  const SizedBox(height: 30),

                  // Announcements Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pengumuman',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lihat Semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      return _buildAnnouncementCard(_announcements[index]);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 15,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mapel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
      IconData icon, String count, String label, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: course['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    course['icon'],
                    color: course['color'],
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              course['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              course['teacher'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: assignment['isUrgent']
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.assignment,
            color:
                assignment['isUrgent'] ? Colors.red : const Color(0xFF1976D2),
            size: 24,
          ),
        ),
        title: Text(
          assignment['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              assignment['course'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: assignment['isUrgent'] ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 5),
                Text(
                  assignment['deadline'],
                  style: TextStyle(
                    color: assignment['isUrgent'] ? Colors.red : Colors.grey,
                    fontWeight: assignment['isUrgent']
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF1976D2),
            ),
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    announcement['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    announcement['date'],
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement['content'],
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                ),
                label: const Text('Baca Selengkapnya'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
