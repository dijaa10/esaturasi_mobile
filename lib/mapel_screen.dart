import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapelScreen extends StatefulWidget {
  @override
  _MapelScreenState createState() => _MapelScreenState();
}

class _MapelScreenState extends State<MapelScreen> {
  List<String> mataPelajaran = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMataPelajaran();
  }

  // Fungsi untuk mengambil data Mata Pelajaran berdasarkan kelas_id
  Future<void> _fetchMataPelajaran() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token'); // Pastikan token ada
      final String? idKelas =
          prefs.getString('kelas_id'); // Pastikan id_kelas ada

      if (token == null || idKelas == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token atau ID Kelas tidak ditemukan';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/mata-pelajaran/$idKelas'), // API endpoint yang sesuai
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            mataPelajaran = List<String>.from(data['mata_pelajaran'].map(
                (item) =>
                    item['nama_mapel'])); // Ambil nama_mapel dari response
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Data tidak ditemukan';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat data mata pelajaran';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        title: Text('Mata Pelajaran', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Menunggu data
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage)) // Menampilkan error
              : ListView.builder(
                  itemCount: mataPelajaran.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: ListTile(
                        title: Text(
                          mataPelajaran[index],
                          style: TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          'Detail Pelajaran ${mataPelajaran[index]}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                        onTap: () {
                          // Aksi ketika item diklik, bisa ditambahkan navigasi ke detail pelajaran
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
