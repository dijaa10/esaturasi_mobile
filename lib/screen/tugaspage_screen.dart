import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/tugas.dart';
import 'dart:convert';
import 'detailtugas_screen.dart';

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
  String nama = "";
  String namaKelas = "Memuat...";
  String fotoProfil = "";
  String currentTab = 'Semua';
  final String baseUrl = "https://esaturasi.my.id/";
  bool _isLoading = true;

  final Map<String, Color> _subjectColors = {};
  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Updated tab logic for 3 tabs
          switch (_tabController.index) {
            case 0:
              currentTab = 'Semua';
              break;
            case 1:
              currentTab = 'Belum Dikerjakan';
              break;
            case 2:
              currentTab = 'Selesai';
              break;
          }
        });
        _filterTasks();
      }
    });

    fetchTasks();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Nama Tidak Ditemukan";
      String fotoPath = prefs.getString('avatar_url') ?? "";
      fotoProfil = fotoPath.isNotEmpty
          ? "${baseUrl}storage/$fotoPath"
          : "https://via.placeholder.com/150";
    });

    String? classroomId = prefs.getString('classroom_id');
    if (classroomId != null) _fetchKelas(classroomId);
  }

  Future<void> _fetchKelas(String classroomId) async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/get-class/$classroomId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaKelas = data['name'] ?? "Kelas Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaKelas = "Gagal Memuat Kelas";
      });
    }
  }

  Future<void> fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${baseUrl}api/tugas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        setState(() {
          tasks = jsonResponse.map((task) => Tugas.fromJson(task)).toList();
          _filterTasks();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal memuat tugas: Error ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tugas: ${e.toString()}')),
      );
    }
  }

  void _filterTasks() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final mapel = task.mataPelajaran ?? '';
        final judul = task.judul ?? '';
        final searchMatch =
            mapel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                judul.toLowerCase().contains(_searchQuery.toLowerCase());

        // Updated filter logic for 3 tabs
        bool statusMatch;
        switch (currentTab) {
          case 'Semua':
            statusMatch = true; // Show all tasks
            break;
          case 'Belum Dikerjakan':
            statusMatch = task.status?.toLowerCase() != 'submitted' &&
                task.status?.toLowerCase() != 'sudah dikumpulkan';
            break;
          case 'Selesai':
            statusMatch = task.status?.toLowerCase() == 'submitted' ||
                task.status?.toLowerCase() == 'sudah dikumpulkan';
            break;
          default:
            statusMatch = true;
        }

        return searchMatch && statusMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String subjectName) {
    if (!_subjectColors.containsKey(subjectName)) {
      _subjectColors[subjectName] =
          _availableColors[_subjectColors.length % _availableColors.length];
    }
    return _subjectColors[subjectName]!;
  }

  String _formatDeadline(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration difference = deadline.difference(now);

      if (difference.isNegative) return 'Tenggat terlewat!';
      if (difference.inDays == 0)
        return 'Hari ini, ${DateFormat('HH:mm').format(deadline)}';
      if (difference.inDays == 1)
        return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
      if (difference.inDays < 7) return '${difference.inDays} hari lagi';

      return DateFormat('dd MMM yyyy, HH:mm').format(deadline);
    } catch (_) {
      return 'Format tanggal tidak valid';
    }
  }

  // Helper method to check if deadline is overdue
  bool _isDeadlineOverdue(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      return deadline.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  // Helper method to get appropriate empty state message
  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'Tidak ada tugas yang sesuai pencarian';
    }

    switch (currentTab) {
      case 'Semua':
        return 'Belum ada tugas';
      case 'Belum Dikerjakan':
        return 'Tidak ada tugas yang belum dikerjakan';
      case 'Selesai':
        return 'Belum ada tugas yang selesai';
      default:
        return 'Tidak ada tugas';
    }
  }

  // Helper method to get appropriate empty state icon
  IconData _getEmptyStateIcon() {
    switch (currentTab) {
      case 'Semua':
        return Icons.assignment_late;
      case 'Belum Dikerjakan':
        return Icons.assignment_outlined;
      case 'Selesai':
        return Icons.check_circle_outline;
      default:
        return Icons.assignment_late;
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getEmptyStateIcon(),
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _getEmptyStateMessage(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchTasks,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailTugasPage(task: task),
                                  ),
                                );

                                if (result == true) {
                                  await fetchTasks();
                                  _tabController.animateTo(
                                      2); // Navigate to 'Selesai' tab
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Tugas berhasil dikumpulkan'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: buildTaskCard(task),
                            );
                          },
                        ),
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
            _filterTasks();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari Tugas',
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
              _searchQuery = '';
              _searchController.clear();
              _filterTasks();
            });
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
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: fotoProfil.isNotEmpty
                              ? Image.network(
                                  fotoProfil,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person,
                                          size: 60, color: Colors.grey),
                                )
                              : Icon(Icons.person,
                                  size: 60, color: Colors.grey),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(namaKelas,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
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
        boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF1A237E),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF1A237E),
        indicatorWeight: 3,
        isScrollable: false,
        tabs: [
          Tab(icon: Icon(Icons.assignment), text: 'Semua'),
          Tab(icon: Icon(Icons.assignment_outlined), text: 'Tertunda'),
          Tab(icon: Icon(Icons.check_circle), text: 'Selesai'),
        ],
      ),
    );
  }

  Widget buildTaskCard(Tugas task) {
    // Check completion status
    final bool isCompleted = task.status?.toLowerCase() == 'submitted' ||
        task.status?.toLowerCase() == 'sudah dikumpulkan';

    // Check if deadline is overdue
    final bool isOverdue = _isDeadlineOverdue(task.deadline ?? "");

    // Determine status text, icon, and color based on completion and deadline
    IconData statusIcon;
    String statusText;
    Color statusColor;

    if (isCompleted) {
      statusIcon = Icons.check_circle;
      statusText = 'Selesai';
      statusColor = Colors.green;
    } else if (isOverdue) {
      statusIcon = Icons.assignment_late;
      statusText = 'Terlewat Deadline';
      statusColor = Colors.red;
    } else {
      statusIcon = Icons.assignment_outlined;
      statusText = 'Belum Dikerjakan';
      statusColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Warna vertikal di sisi kiri
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: _getSubjectColor(task.mataPelajaran ?? ""),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 16),
            // Isi teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Mapel
                  Text(
                    task.mataPelajaran ?? "Tidak diketahui",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 6),
                  // Judul tugas
                  Text(
                    task.judul ?? "Judul kosong",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  // Deadline with conditional color
                  Text(
                    'Deadline: ${_formatDeadline(task.deadline ?? "")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue && !isCompleted
                          ? Colors.red
                          : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontWeight: isOverdue && !isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Status tugas
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 18,
                        color: statusColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Status: $statusText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  // Jika ada nilai
                  if (task.score != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.grade, size: 18, color: Colors.amber[800]),
                        SizedBox(width: 6),
                        Text(
                          'Nilai: ${task.score}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Panah kanan
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
