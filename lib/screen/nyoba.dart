import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning SMK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
      ),
      home: const ELearningHomePage(),
    );
  }
}

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
    {
      'title': 'Desain UI Aplikasi Mobile',
      'course': 'Pemrograman Mobile',
      'deadline': '2 hari lagi',
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
    {
      'title': 'Workshop Kewirausahaan',
      'content':
          'Workshop kewirausahaan akan diadakan pada hari Sabtu, 22 Maret 2025.',
      'date': '3 Maret 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'E-Learning SMK',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_studentName),
              accountEmail: Text(_studentClass),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(_avatarUrl),
              ),
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Kelas Saya'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Tugas'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Jadwal'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Ujian'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Bantuan'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with welcome message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(_avatarUrl),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang,',
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
                          Icons.book, '4', 'Kelas Aktif', Colors.green),
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
                        'Kelas Saya',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua'),
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
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua'),
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
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua'),
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
            label: 'Kelas',
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
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: course['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    course['icon'],
                    color: course['color'],
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(course['progress'] * 100).toInt()}%',
                  style: TextStyle(
                    color: course['color'],
                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: course['progress'],
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(course['color']),
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: assignment['isUrgent']
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.assignment,
            color: assignment['isUrgent'] ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          assignment['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(assignment['course']),
            const SizedBox(height: 3),
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
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {},
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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  announcement['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  announcement['date'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement['content'],
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Baca Selengkapnya'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
