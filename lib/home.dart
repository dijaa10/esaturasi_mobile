import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import intl untuk format tanggal
import 'mapel_screen.dart'; // Import halaman MapelScreen
import 'calendar_screen.dart'; // Import halaman CalendarScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nama = "";
  String nisn = ""; // Ganti email dengan nisn
  String fotoProfil = "";
  final String baseUrl = "http://127.0.0.1:8000/";
  String currentDate = ""; // Untuk menyimpan tanggal saat ini
  String greeting = ""; // Untuk menyimpan greeting message

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setCurrentDate(); // Memanggil method untuk mendapatkan tanggal hari ini
    _setGreeting(); // Memanggil method untuk menentukan greeting berdasarkan waktu
  }

  // untuk mengambil data dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nama = prefs.getString('nama') ?? "Nama Tidak Ditemukan";
      nisn = prefs.getString('nisn') ??
          "NISN Tidak Ditemukan"; // Ambil nisn dari SharedPreferences
      String fotoPath = prefs.getString('foto_profil') ?? "";
      fotoProfil = fotoPath.isNotEmpty
          ? "${baseUrl}storage/$fotoPath"
          : "https://via.placeholder.com/150";
    });
  }

  // Method untuk mendapatkan tanggal hari ini
  void _setCurrentDate() {
    final now = DateTime.now();
    setState(() {
      currentDate = DateFormat('d MMMM yyyy').format(now); // Format tanggal
    });
  }

  // Method untuk menentukan greeting berdasarkan waktu
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text(
          greeting, // Use dynamic greeting
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue,
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
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(fotoProfil),
                      ),
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
                            nisn, // Menampilkan NISN
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
                  currentDate, // Menampilkan tanggal hari ini
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
