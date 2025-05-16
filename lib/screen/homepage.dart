import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:timeago/timeago.dart' as timeago;
import '../model/announcement.dart';
import 'announcementdetailpage.dart';
import 'announcementpage.dart';
import '../model/jadwal.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String name = "";
  String nameClass = "Memuat...";
  String fotoProfil = "";
  final String baseUrl = "http://10.0.2.2:8000/";

  String currentDate = "";
  String greeting = "";
  bool isImageLoading = true;
  bool hasImageError = false;
  List<Jadwal> semuaJadwal = [];
  List<Map<String, dynamic>> _courses = [];

  final List<IconData> randomIcons = [
    Icons.computer,
    Icons.storage,
    Icons.phone_android,
    Icons.brush,
    Icons.book,
    Icons.code,
    Icons.calculate,
    Icons.science,
  ];

  final List<IconData> icons = [
    Icons.computer,
    Icons.storage,
    Icons.phone_android,
    Icons.brush,
    Icons.book,
    Icons.school,
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    _loadUserData();
    _setGreeting();

    // Inisialisasi data lokal Indonesia
    initializeDateFormatting('id_ID', null).then((_) {
      // Setelah inisialisasi, ambil data jadwal
      _fetchJadwal();
    });
  }

  String timeAgo(DateTime date) {
    return timeago.format(date, locale: 'id');
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "Nama Tidak Ditemukan";
      String fotoPath = prefs.getString('avatar_url') ?? "";
      fotoProfil = fotoPath.isNotEmpty
          ? "${baseUrl}storage/$fotoPath"
          : "https://via.placeholder.com/150";
    });

    String? classroom_id = prefs.getString('classroom_id');
    if (classroom_id != null) _fetchKelas(classroom_id);
  }

  Future<void> _fetchKelas(String classroom_id) async {
    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/get-class/$classroom_id"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nameClass = data['name'] ?? "Kelas Tidak Ditemukan";
        });
      }
    } catch (e) {
      setState(() {
        nameClass = "Gagal Memuat Kelas";
      });
    }
  }

  void _setGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      greeting = "Selamat Pagi";
    } else if (hour >= 12 && hour < 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }
  }

  String getHariIni() {
    final hari = DateTime.now().weekday;
    const namaHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return namaHari[hari - 1];
  }

  Future<void> _fetchJadwal() async {
    final prefs = await SharedPreferences.getInstance();
    final kelasId = prefs.getString('kelas_id');

    if (kelasId == null) {
      print("ID Kelas tidak ditemukan");
      return;
    }

    try {
      final response =
          await http.get(Uri.parse("${baseUrl}api/jadwal/kelas/$kelasId"));

      print("Status API Jadwal: ${response.statusCode}");
      print("Response API: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Jadwal> jadwalList = (data['data'] as List)
            .map((item) => Jadwal.fromJson(item))
            .toList();

        print("Jumlah jadwal diterima: ${jadwalList.length}");

        setState(() {
          semuaJadwal = jadwalList;
          _courses = getCoursesToday(jadwalList);
        });
      } else {
        print("Gagal mengambil jadwal: ${response.statusCode}");
      }
    } catch (e) {
      print("Error saat mengambil jadwal: $e");
    }
  }

  List<Map<String, dynamic>> getCoursesToday(List<Jadwal> jadwals) {
    if (jadwals.isEmpty) {
      print("Tidak ada jadwal yang tersedia sama sekali");
      return [];
    }

    // Dapatkan nama hari dalam bahasa Indonesia dari Intl
    final todayIntl = DateFormat.EEEE('id_ID').format(DateTime.now());
    print("Hari ini (Intl): $todayIntl");

    // Dapatkan nama hari dengan cara manual - sebagai alternatif
    final todayManual = getHariIni();
    print("Hari ini (Manual): $todayManual");

    // Debug: Tampilkan semua jadwal yang ada
    print("Semua jadwal yang tersedia:");
    jadwals.forEach((j) {
      print("- ${j.hari}: ${j.mataPelajaran} (${j.guru})");
    });

    // Coba cari dengan beberapa cara berbeda
    final filtered = jadwals
        .where((j) =>
            j.hari.toLowerCase() == todayIntl.toLowerCase() ||
            j.hari.toLowerCase() == todayManual.toLowerCase())
        .toList();

    print("Jumlah jadwal hari ini: ${filtered.length}");

    if (filtered.isEmpty) {
      print("Tidak ada jadwal untuk hari: $todayIntl/$todayManual");

      // Cek apakah mungkin ada masalah dengan format hari
      print("Format hari di database vs aplikasi:");
      final uniqueDays = jadwals.map((j) => j.hari).toSet().toList();
      print("Hari di database: $uniqueDays");
    }

    return filtered.map((j) {
      return {
        'title': j.mataPelajaran,
        'teacher': j.guru,
        'color': Colors.primaries[Random().nextInt(Colors.primaries.length)],
        'icon': icons[Random().nextInt(icons.length)],
      };
    }).toList();
  }

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

  List<Announcement> _announcements = [];
  bool _isLoading = true;
  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}api/announcement"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _announcements =
              data.map((item) => Announcement.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Gagal mengambil data pengumuman: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching pengumuman: $e");
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

// Fungsi untuk membangun card jadwal pelajaran
  Widget buildCourseCard(Map<String, dynamic> course) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: course['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                course['icon'],
                color: course['color'],
                size: 35,
              ),
              const SizedBox(height: 15),
              Text(
                course['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                course['teacher'],
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: fotoProfil.isNotEmpty
                              ? Image.network(
                                  fotoProfil,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print("ERROR loading image: $error");
                                    return const Icon(Icons.person,
                                        size: 40, color: Colors.grey);
                                  },
                                )
                              : const Icon(Icons.person,
                                  size: 60, color: Colors.grey),
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
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              nameClass,
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
                      _buildActivityCard(Icons.assignment, '0',
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
                        onPressed: () {
                          // Navigasi ke halaman semua jadwal
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lihat Semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _courses.isNotEmpty
                      ? SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              return buildCourseCard(_courses[index]);
                            },
                          ),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Tidak ada jadwal hari ini.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Announcementpage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Lihat Semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator()) // Loading indicator
                      : _announcements.isEmpty
                          ? const Center(
                              child:
                                  Text("Tidak ada pengumuman")) // Jika kosong
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              // Limit to maximum 2 announcements
                              itemCount: _announcements.length > 2
                                  ? 2
                                  : _announcements.length,
                              itemBuilder: (context, index) {
                                return _buildAnnouncementCard(
                                    _announcements[index]);
                              },
                            ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildAnnouncementCard(Announcement announcement) {
    // Format the date here
    String formattedDate = _formatDate(announcement.date);

    // Extract plain text from content if it contains HTML
    String plainContent = _extractTextFromHtml(announcement.content);

    // Limit content to 100 characters
    String limitedContent = _limitToChars(plainContent, 115);

    // Check if content was truncatedn
    bool isTruncated = plainContent != limitedContent;

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
                    announcement.title,
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
                    formattedDate,
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
            // Display plain text without HTML formatting, limited to 100 characters
            Text(
              limitedContent + (isTruncated ? "..." : ""),
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Announcementdetailpage(announcement: announcement),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
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

// Function to extract plain text from HTML content
  String _extractTextFromHtml(String htmlString) {
    // Simple regex to remove HTML tags
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities if needed
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return result;
  }

// Function to format regular dates
  String _formatDate(String dateString) {
    try {
      // For dates that might contain HTML, extract text first
      if (dateString.contains('<')) {
        dateString = _extractTextFromHtml(dateString);
      }

      // Try to parse as regular date
      DateTime date = DateTime.parse(dateString);

      List<String> monthNames = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      return "${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } catch (e) {
      // If parsing fails, just return cleaned text
      if (dateString.contains('<')) {
        return _extractTextFromHtml(dateString);
      }
      return dateString;
    }
  }

// New function to limit text to specific number of characters
  String _limitToChars(String text, int charLimit) {
    // If the text has fewer characters than the limit, return the original text
    if (text.length <= charLimit) {
      return text;
    }

    // Otherwise, return only the first 'charLimit' characters
    return text.substring(0, charLimit);
  }
}
