import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:timeago/timeago.dart' as timeago;
import 'package:esaturasi/screen/detail_pengumuman_screen.dart';

class PengumumanScreen extends StatefulWidget {
  @override
  _PengumumanScreenState createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  List<dynamic> _pengumumanList = [];
  final String apiUrl = 'http://127.0.0.1:8000/api/pengumuman';
  int? _hoveredIndex; // Untuk menyimpan indeks card yang dihover

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    ambilPengumuman();
  }

  Future<void> ambilPengumuman() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          _pengumumanList = json.decode(response.body);
        });
      } else {
        throw Exception('Gagal memuat pengumuman');
      }
    } catch (e) {
      print("Terjadi kesalahan: $e");
    }
  }

  String waktuBerlalu(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return timeago.format(dateTime, locale: 'id');
    } catch (e) {
      return "Waktu tidak valid";
    }
  }

  String potongDeskripsi(String deskripsi, int jumlahHuruf) {
    if (deskripsi.length > jumlahHuruf) {
      return deskripsi.substring(0, jumlahHuruf) + '...';
    }
    return deskripsi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        title: Text(
          'Pengumuman Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: _pengumumanList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "Tidak ada pengumuman",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _pengumumanList.length,
              itemBuilder: (context, index) {
                final pengumuman = _pengumumanList[index];

                Uint8List? gambarBytes;
                if (pengumuman['gambar'] != null) {
                  try {
                    gambarBytes = base64Decode(pengumuman['gambar']);
                  } catch (e) {
                    print("Kesalahan saat mengubah gambar: $e");
                  }
                }

                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveredIndex = index;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredIndex = null;
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailPengumumanScreen(pengumuman: pengumuman),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: _hoveredIndex == index
                          ? Colors.grey[200] // Warna berubah saat hover
                          : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          gambarBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.memory(
                                    gambarBytes,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child:
                                      Center(child: Text("Tidak ada gambar")),
                                ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pengumuman['judul_pengumuman'] ??
                                      "Tanpa Judul",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  potongDeskripsi(
                                      pengumuman['deskripsi_pengumuman'] ??
                                          "Tidak ada deskripsi",
                                      130),
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 5),
                                    Text(
                                      waktuBerlalu(
                                          pengumuman['created_at'] ?? ""),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
