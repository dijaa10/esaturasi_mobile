import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../model/tugas.dart';
import 'dart:convert';
import 'detailtugas_screen.dart'; // Pastikan untuk mengimpor halaman DetailTugasPage

class TugasSiswaPage extends StatefulWidget {
  @override
  _TugasSiswaPageState createState() => _TugasSiswaPageState();
}

class _TugasSiswaPageState extends State<TugasSiswaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Tugas> tasks = [];
  List<Tugas> filteredTasks = [];
  String _studentName = "Ahmad Fauzi";
  String _className = "XI IPA 2";
  String _currentSemester = "Semester 2 - 2024/2025";
  String currentTab = 'Semua'; // Track the current selected tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTasks(); // Fetch tasks when the page loads
  }

  Future<void> fetchTasks() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/api/tugas'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
        tasks = jsonResponse.map((task) => Tugas.fromJson(task)).toList();
        filteredTasks =
            List.from(tasks); // Initialize filtered tasks with all tasks
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tugas, coba lagi nanti')),
      );
    }
  }

  void _filterTasks() {
    setState(() {
      filteredTasks = tasks.where((task) {
        return task.judul.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      // Filter tasks based on the selected tab
      if (currentTab == 'Menunggu') {
        filteredTasks =
            filteredTasks.where((task) => task.status == 'Menunggu').toList();
      } else if (currentTab == 'Selesai') {
        filteredTasks =
            filteredTasks.where((task) => task.status == 'Selesai').toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String subjectName) {
    switch (subjectName) {
      case 'kelistrikan kendaraan':
        return Colors.blue;
      case 'Bahasa Indonesia':
        return Colors.red;
      case 'IPA':
        return Colors.green;
      case 'IPS':
        return Colors.orange;
      case 'Bahasa Inggris':
        return Colors.purple;
      case 'Pendidikan Agama':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDeadline(String deadlineStr) {
    try {
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
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isSearching ? _buildSearchAppBar() : _buildCustomAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigasi ke halaman detail tugas saat kartu tugas diketuk
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailTugasPage(task: task),
                            ),
                          );
                        },
                        child: buildTaskCard(task),
                      );
                    },
                  ),
          ),
        ],
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
          _filterTasks();
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
            _filterTasks();
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
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
                          _studentName.split(' ').map((e) => e[0]).join(''),
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
                    ],
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
          if (index == 0) {
            setState(() {
              currentTab = 'Semua';
            });
          } else if (index == 1) {
            setState(() {
              currentTab = 'Menunggu';
            });
          } else if (index == 2) {
            setState(() {
              currentTab = 'Selesai';
            });
          }
          _filterTasks();
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

  Widget buildTaskCard(Tugas task) {
    final Color subjectColor = _getSubjectColor(task.judul);
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
                Icon(Icons.assignment, color: subjectColor, size: 20),
                SizedBox(width: 8),
                Text(
                  task.judul,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: subjectColor),
                ),
                Spacer(),
                _buildStatusChip(task.status),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.judul,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(task.deskripsi),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(task.guru, style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${task.attachments} lampiran',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(_formatDeadline(task.deadline)),
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
}
