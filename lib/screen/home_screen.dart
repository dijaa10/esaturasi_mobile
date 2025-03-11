import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import intl untuk format tanggal
import 'package:intl/date_symbol_data_local.dart'; // Import untuk localization
import 'package:cached_network_image/cached_network_image.dart'; // Tambahkan package ini untuk mengelola cache gambar
import 'package:esaturasi/screen/calendar_screen.dart';
import 'package:esaturasi/screen/mapel_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nama = "";
  String nisn = "";
  String fotoProfil = "";
  final String baseUrl = "http://127.0.0.1:8000/";
  String currentDate = "";
  String greeting = "";
  bool isImageLoading = true;
  bool hasImageError = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi locale data untuk Bahasa Indonesia
    initializeDateFormatting('id_ID', null).then((_) {
      _setCurrentDate(); // Memanggil method untuk mendapatkan tanggal hari ini
    });
    _loadUserData();
    _setGreeting(); // Memanggil method untuk menentukan greeting berdasarkan waktu
  }

  // untuk mengambil data dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nama = prefs.getString('nama') ?? "Nama Tidak Ditemukan";
      nisn = prefs.getString('nisn') ?? "NISN Tidak Ditemukan";
      String fotoPath = prefs.getString('foto_profil') ?? "";

      // Pastikan URL foto profil valid
      if (fotoPath.isNotEmpty) {
        fotoProfil = "${baseUrl}storage/$fotoPath";
      } else {
        fotoProfil = ""; // Set string kosong jika tidak ada foto
        hasImageError = true;
      }
    });

    // Cek apakah URL foto valid dengan pre-loading
    if (fotoProfil.isNotEmpty) {
      precacheImage(NetworkImage(fotoProfil), context).then((_) {
        setState(() {
          isImageLoading = false;
        });
      }).catchError((error) {
        print("Error precaching image: $error");
        setState(() {
          hasImageError = true;
          isImageLoading = false;
        });
      });
    }
  }

  // Method untuk mendapatkan tanggal hari ini dengan format Bahasa Indonesia
  void _setCurrentDate() {
    final now = DateTime.now();
    setState(() {
      // Format tanggal dengan locale Indonesia
      currentDate = DateFormat('d MMMM yyyy', 'id_ID').format(now);
    });
  }

  // Method untuk menentukan greeting berdasarkan waktu
  void _setGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }
  }

  // Widget untuk menampilkan foto profil dengan penanganan error
  Widget _buildProfileImage() {
    if (isImageLoading) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[300],
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      );
    } else if (hasImageError || fotoProfil.isEmpty) {
      // Tampilkan avatar placeholder dengan inisial nama jika ada error atau tidak ada foto
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.blueGrey,
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : "?",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Gunakan CachedNetworkImage untuk caching dan penanganan error yang lebih baik
      return ClipOval(
        child: Container(
          width: 80,
          height: 80,
          child: Image.network(
            fotoProfil,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print("Error loading image: $error");
              return CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueGrey,
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : "?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: Colors.yellow, size: 26),
            SizedBox(width: 8),
            Text(
              greeting,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.person, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildProfileImage(),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            nama,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'NISN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            nisn,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuItem(
                    'assets/images/ic_jamnew.png', 'Jadwal', Colors.orange),
                _buildMenuItem(
                    'assets/images/ic_tugasnew.png', 'Tugas', Colors.green),
                _buildMenuItem(
                    'assets/images/ic_mapelnew.png', 'Mapel', Colors.pink),
                _buildMenuItem('assets/images/ic_kalendernew.png', 'Kalender',
                    Colors.blue),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Hari Ini',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentDate, // Menampilkan tanggal hari ini dalam Bahasa Indonesia
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('Pelajaran ${index + 1}'),
                    subtitle: Text('Detail Jadwal'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String iconPath, String title, Color color) {
    return GestureDetector(
      onTap: () {
        if (title == 'Mapel') {
          // Navigasi ke halaman Mapel
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapelScreen()),
          );
        } else if (title == 'Kalender') {
          // Navigasi ke halaman Kalender
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    CalendarScreen()), // Navigasi ke CalendarScreen
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(iconPath, width: 40, height: 40),
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
