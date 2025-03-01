import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  String namaSiswa = "";
  String namaKelas = "";
  String namaJurusan = "";
  Map<String, dynamic> dataKelas = {};
  Map<String, dynamic> dataSiswa = {};

  @override
  void initState() {
    super.initState();
    _ambilDataPengguna();
  }

  // Fungsi untuk mengambil data pengguna dari SharedPreferences
  Future<void> _ambilDataPengguna() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil token dan data dari SharedPreferences
      final token = prefs.getString('token');
      final siswaId = prefs.getString('siswa_id');
      final nama = prefs.getString('nama') ?? 'Siswa';
      final kelasId = prefs.getString('kelas_id');

      setState(() {
        namaSiswa = nama;
      });

      if (token != null) {
        // Ambil profil lengkap siswa dengan relasi
        await _ambilProfilSiswa(token);
      }
    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
      _tampilkanPesanError("Terjadi kesalahan saat memuat data");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk mengambil profil siswa dari API
  Future<void> _ambilProfilSiswa(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/siswa/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            dataSiswa = data['data'];

            // Ambil data kelas dan jurusan dari response
            if (data['data']['kelas'] != null) {
              dataKelas = data['data']['kelas'];
              namaKelas = dataKelas['nama_kelas'] ?? '';
            }

            if (data['data']['jurusan'] != null) {
              namaJurusan = data['data']['jurusan']['nama_jurusan'] ?? '';
            }
          });
        } else {
          _tampilkanPesanError("Data profil tidak valid");
        }
      } else if (response.statusCode == 401) {
        _tampilkanPesanError("Sesi habis, silakan login kembali");
        _keluarAplikasi();
      } else {
        _tampilkanPesanError("Gagal mengambil data profil");
      }
    } catch (e) {
      print("Error mengambil profil: $e");
      _tampilkanPesanError("Terjadi kesalahan saat memuat profil");
    }
  }

  // Fungsi untuk menampilkan pesan error
  void _tampilkanPesanError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Fungsi untuk logout dan kembali ke halaman login
  Future<void> _keluarAplikasi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Panggil API logout jika token tersedia
    if (token != null) {
      try {
        await http.post(
          Uri.parse('http://127.0.0.1:8000/api/siswa/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (e) {
        print("Error saat logout: $e");
      }
    }

    // Hapus semua data dari SharedPreferences
    await prefs.clear();

    // Navigasi ke halaman login
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: const Color(0xFF2446CE),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _keluarAplikasi();
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE9EDF6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _ambilDataPengguna(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header dengan informasi siswa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2446CE),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selamat Datang,",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            namaSiswa,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (namaKelas.isNotEmpty)
                            Text(
                              "Kelas $namaKelas",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          if (namaJurusan.isNotEmpty)
                            Text(
                              "Jurusan $namaJurusan",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Informasi kelas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Informasi Kelas",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              namaKelas.isNotEmpty
                                  ? "Selamat datang di kelas $namaKelas"
                                  : "Informasi kelas belum tersedia",
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            if (namaJurusan.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Jurusan: $namaJurusan",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Informasi siswa
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Data Siswa",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow("NISN", dataSiswa['nisn'] ?? "-"),
                            _buildInfoRow("Nama", dataSiswa['nama'] ?? "-"),
                            _buildInfoRow(
                                "Jenis Kelamin",
                                dataSiswa['jenis_kelamin'] != null
                                    ? (dataSiswa['jenis_kelamin'] == 'laki-laki'
                                        ? 'Laki-laki'
                                        : 'Perempuan')
                                    : "-"),
                            _buildInfoRow("Tanggal Lahir",
                                dataSiswa['tanggal_lahir'] ?? "-"),
                            _buildInfoRow("Tempat Lahir",
                                dataSiswa['tempat_lahir'] ?? "-"),
                            _buildInfoRow("Alamat", dataSiswa['alamat'] ?? "-"),
                            _buildInfoRow("Email", dataSiswa['email'] ?? "-"),
                            _buildInfoRow("Tahun Masuk",
                                dataSiswa['tahun_masuk']?.toString() ?? "-"),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper untuk menampilkan baris informasi
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}
