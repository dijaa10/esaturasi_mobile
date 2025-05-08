import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String nama = "";
  String namaKelas = "Memuat...";
  String fotoProfil = "";
  String currentTab = 'Semua';
  final String baseUrl = "http://10.0.2.2:8000/";

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
    _tabController = TabController(length: 2, vsync: this);
    fetchTasks();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? "Nama Tidak Ditemukan";
      String fotoPath = prefs.getString('foto_profil') ?? "";
      fotoProfil = fotoPath.isNotEmpty
          ? "${baseUrl}storage/$fotoPath"
          : "https://via.placeholder.com/150";
    });

    String? idKelas = prefs.getString('kelas_id');
    if (idKelas != null) _fetchKelas(idKelas);
  }

  Future<void> _fetchKelas(String idKelas) async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/get-kelas/$idKelas"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaKelas = data['nama_kelas'] ?? "Kelas Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        namaKelas = "Gagal Memuat Kelas";
      });
    }
  }

  Future<void> fetchTasks() async {
    final response = await http.get(Uri.parse('${baseUrl}api/tugas'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
        tasks = jsonResponse.map((task) => Tugas.fromJson(task)).toList();
        filteredTasks = List.from(tasks);
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
        final mapel = task.mataPelajaran ?? '';
        return mapel.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      if (currentTab == 'Selesai') {
        filteredTasks = filteredTasks
            .where((task) => task.status == 'Sudah Dikumpulkan')
            .toList();
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
              _isSearching = false;
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
        onTap: (index) {
          setState(() {
            currentTab = index == 0 ? 'Semua' : 'Selesai';
          });
          _filterTasks();
        },
        tabs: [
          Tab(icon: Icon(Icons.assignment), text: 'Semua'),
          Tab(icon: Icon(Icons.check_circle), text: 'Selesai'),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment, color: subjectColor, size: 20),
                SizedBox(width: 8),
                Text(task.judul,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: subjectColor)),
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
                Text(task.judul,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
