import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'detail_artikel_screen.dart'; // Halaman detail artikel
import 'model/pengumuman.dart'; // Model pengumuman

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({Key? key}) : super(key: key);
  @override
  _ArtikelScreenState createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  List<Pengumuman> pengumumanList = [];
  final String baseUrl = 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    fetchPengumuman();
  }

  Future<void> fetchPengumuman() async {
    final response = await http.get(Uri.parse('$baseUrl/api/pengumuman'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Pengumuman> tempList = (data['pengumuman'] as List)
          .map((json) => Pengumuman.fromJson(json))
          .toList();

      setState(() {
        pengumumanList = tempList;
      });
    } else {
      throw Exception('Gagal mengambil data pengumuman');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Artikel', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: pengumumanList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: pengumumanList.length,
              itemBuilder: (context, index) {
                return _buildArticleCard(context, pengumumanList[index]);
              },
            ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Pengumuman pengumuman) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailArtikelScreen(
              title: pengumuman.judul,
              content: pengumuman.content,
              arsipPath: pengumuman.arsipPath, // Kirim path gambar
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan gambar jika tersedia
            if (pengumuman.arsipPath != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  '$baseUrl/storage/${pengumuman.arsipPath}',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengumuman.judul,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pengumuman.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
