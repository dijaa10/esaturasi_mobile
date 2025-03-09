import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TugasSiswaPage extends StatefulWidget {
  @override
  _TugasSiswaPageState createState() => _TugasSiswaPageState();
}

class _TugasSiswaPageState extends State<TugasSiswaPage>
    with SingleTickerProviderStateMixin {
  // Data mata pelajaran
  final List<Map<String, dynamic>> subjects = [
    {'name': 'Matematika', 'color': Colors.blue, 'icon': Icons.calculate},
    {'name': 'Bahasa Indonesia', 'color': Colors.red, 'icon': Icons.book},
    {'name': 'IPA', 'color': Colors.green, 'icon': Icons.science},
    {'name': 'IPS', 'color': Colors.orange, 'icon': Icons.public},
    {'name': 'Bahasa Inggris', 'color': Colors.purple, 'icon': Icons.language},
    {'name': 'Pendidikan Agama', 'color': Colors.teal, 'icon': Icons.menu_book},
  ];

  // Data daftar tugas siswa
  List<Map<String, dynamic>> tasks = [
    {
      'title': 'Tugas Matematika Persamaan Kuadrat',
      'subject': 'Matematika',
      'deadline': '2025-03-12 23:59',
      'teacher': 'Pak Budi',
      'description': 'Kerjakan soal halaman 45-46 nomor 1-10',
      'status': 'Belum Dikerjakan',
      'attachments': 2,
      'score': null
    },
    {
      'title': 'Makalah Sejarah Kemerdekaan',
      'subject': 'IPS',
      'deadline': '2025-03-15 23:59',
      'teacher': 'Bu Siti',
      'description':
          'Buat makalah tentang peristiwa sebelum kemerdekaan, minimal 5 halaman',
      'status': 'Sedang Dikerjakan',
      'attachments': 1,
      'score': null
    },
    {
      'title': 'Praktikum Fotosintesis',
      'subject': 'IPA',
      'deadline': '2025-03-10 23:59',
      'teacher': 'Bu Dewi',
      'description':
          'Lakukan percobaan fotosintesis dan dokumentasikan hasilnya',
      'status': 'Belum Dikerjakan',
      'attachments': 3,
      'score': null
    },
    {
      'title': 'Ringkasan Novel "Laskar Pelangi"',
      'subject': 'Bahasa Indonesia',
      'deadline': '2025-03-05 23:59',
      'teacher': 'Pak Ahmad',
      'description': 'Buat ringkasan novel dan analisis karakter tokoh utama',
      'status': 'Sudah Dikumpulkan',
      'attachments': 1,
      'score': 85
    },
    {
      'title': 'Esai "My Future Plan"',
      'subject': 'Bahasa Inggris',
      'deadline': '2025-03-08 23:59',
      'teacher': 'Ms. Sarah',
      'description': 'Write an essay about your future plan in 500 words',
      'status': 'Sudah Dikumpulkan',
      'attachments': 1,
      'score': 90
    },
    {
      'title': 'Hafalan Surat Pendek',
      'subject': 'Pendidikan Agama',
      'deadline': '2025-03-14 08:00',
      'teacher': 'Pak Hasan',
      'description': 'Hafalan surat Al-Insyirah dan artinya',
      'status': 'Belum Dikerjakan',
      'attachments': 0,
      'score': null
    },
  ];

  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _currentSemester = "Semester 2 - 2024/2025";
  String _studentName = "Ahmad Fauzi";
  String _className = "XI IPA 2";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String subjectName) {
    final subject = subjects.firstWhere(
      (subject) => subject['name'] == subjectName,
      orElse: () => {'color': Colors.grey},
    );
    return subject['color'] as Color;
  }

  IconData _getSubjectIcon(String subjectName) {
    final subject = subjects.firstWhere(
      (subject) => subject['name'] == subjectName,
      orElse: () => {'icon': Icons.assignment},
    );
    return subject['icon'] as IconData;
  }

  String _formatDeadline(String deadlineStr) {
    DateTime deadline = DateTime.parse(deadlineStr);
    DateTime now = DateTime.now();
    Duration difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Tenggat terlewat!';
    } else if (difference.inDays == 0) {
      return 'Hari ini, ${DateFormat('HH:mm').format(deadline)}';
    } else if (difference.inDays == 1) {
      return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lagi';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(deadline);
    }
  }

  List<Map<String, dynamic>> _getFilteredTasks() {
    if (_searchQuery.isEmpty) {
      switch (_tabController.index) {
        case 0:
          return tasks;
        case 1:
          return tasks
              .where((task) => task['status'] != 'Sudah Dikumpulkan')
              .toList();
        case 2:
          return tasks
              .where((task) => task['status'] == 'Sudah Dikumpulkan')
              .toList();
        default:
          return tasks;
      }
    } else {
      return tasks.where((task) {
        return task['title']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            task['subject']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            task['teacher'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung ringkasan statistik untuk ditampilkan
    int totalTasks = tasks.length;
    int pendingTasks =
        tasks.where((task) => task['status'] != 'Sudah Dikumpulkan').length;
    int completedTasks =
        tasks.where((task) => task['status'] == 'Sudah Dikumpulkan').length;
    double completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isSearching
          ? _buildSearchAppBar()
          : _buildCustomAppBar(pendingTasks, completionRate),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _getFilteredTasks().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in,
                            size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada tugas ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _getFilteredTasks().length,
                    itemBuilder: (context, index) {
                      final task = _getFilteredTasks()[index];
                      return buildTaskCard(task);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildUpcomingTasksSheet(),
          );
        },
        icon: Icon(Icons.calendar_today),
        label: Text('Lihat Jadwal'),
        backgroundColor: Color(0xFF1976D2),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF1976D2),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari tugas...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        autofocus: true,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
            });
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(
      int pendingTasks, double completionRate) {
    return PreferredSize(
      preferredSize: Size.fromHeight(150),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: Text(
                          _studentName
                              .split(' ')
                              .map((e) => e[0])
                              .join('')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _studentName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _className,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          // Implementasi notifikasi
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentSemester,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF1A237E),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF1A237E),
        indicatorWeight: 3,
        onTap: (index) {
          setState(() {});
        },
        tabs: [
          Tab(
            icon: Icon(Icons.assignment),
            text: 'Semua',
          ),
          Tab(
            icon: Icon(Icons.pending_actions),
            text: 'Menunggu',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget buildTaskCard(Map<String, dynamic> task) {
    final Color subjectColor = _getSubjectColor(task['subject']);
    final IconData subjectIcon = _getSubjectIcon(task['subject']);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(subjectIcon, color: subjectColor, size: 20),
                SizedBox(width: 8),
                Text(
                  task['subject'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subjectColor,
                  ),
                ),
                Spacer(),
                _buildStatusChip(task['status']),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  task['description'],
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      task['teacher'],
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${task['attachments']} lampiran',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Spacer(),
                    if (task['score'] != null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getScoreColor(task['score']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Nilai: ${task['score']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      _formatDeadline(task['deadline']),
                      style: TextStyle(
                        color: _getDeadlineColor(task['deadline']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    if (task['status'] != 'Sudah Dikumpulkan')
                      TextButton.icon(
                        onPressed: () {
                          // Implementasi kumpulkan tugas
                        },
                        icon: Icon(
                          Icons.upload_file,
                          size: 16,
                        ),
                        label: Text('Kumpulkan'),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF1A237E).withOpacity(0.1),
                          foregroundColor: Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Sudah Dikumpulkan':
        chipColor = Colors.green;
        break;
      case 'Sedang Dikerjakan':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getDeadlineColor(String deadlineStr) {
    DateTime deadline = DateTime.parse(deadlineStr);
    DateTime now = DateTime.now();
    Duration difference = deadline.difference(now);

    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inDays < 2) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) {
      return Colors.green;
    } else if (score >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildUpcomingTasksSheet() {
    // Urutkan tugas berdasarkan deadline
    List<Map<String, dynamic>> upcoming = List.from(tasks);
    upcoming.sort((a, b) {
      DateTime dateA = DateTime.parse(a['deadline']);
      DateTime dateB = DateTime.parse(b['deadline']);
      return dateA.compareTo(dateB);
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_note, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Jadwal Tenggat Tugas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                final task = upcoming[index];
                DateTime deadline = DateTime.parse(task['deadline']);
                String groupDate = DateFormat('d MMMM yyyy').format(deadline);

                // Tampilkan pembatas tanggal jika berbeda dengan tugas sebelumnya
                bool showDateDivider = false;
                if (index == 0) {
                  showDateDivider = true;
                } else {
                  DateTime prevDeadline =
                      DateTime.parse(upcoming[index - 1]['deadline']);
                  String prevGroupDate =
                      DateFormat('d MMMM yyyy').format(prevDeadline);
                  showDateDivider = groupDate != prevGroupDate;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateDivider) ...[
                      if (index > 0) SizedBox(height: 16),
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event,
                                size: 14, color: Color(0xFF1976D2)),
                            SizedBox(width: 4),
                            Text(
                              groupDate,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            backgroundColor: _getSubjectColor(task['subject'])
                                .withOpacity(0.2),
                            radius: 20,
                            child: Icon(
                              _getSubjectIcon(task['subject']),
                              color: _getSubjectColor(task['subject']),
                              size: 20,
                            ),
                          ),
                          if (task['status'] == 'Sudah Dikumpulkan')
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        task['title'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: _getDeadlineColor(task['deadline']),
                              ),
                              SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm').format(deadline),
                                style: TextStyle(
                                  color: _getDeadlineColor(task['deadline']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                task['teacher'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: _buildStatusChip(task['status']),
                    ),
                    if (index < upcoming.length - 1) Divider(),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Tutup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
