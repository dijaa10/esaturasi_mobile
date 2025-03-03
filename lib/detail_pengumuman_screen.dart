import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;

class DetailPengumumanScreen extends StatelessWidget {
  final dynamic pengumuman;

  DetailPengumumanScreen({required this.pengumuman});

  String waktuBerlalu(String tanggal) {
    try {
      DateTime dateTime = DateTime.parse(tanggal);
      return timeago.format(dateTime, locale: 'id');
    } catch (e) {
      return "Waktu tidak valid";
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? gambarBytes;
    if (pengumuman['gambar'] != null) {
      try {
        gambarBytes = base64Decode(pengumuman['gambar']);
      } catch (e) {
        print("Kesalahan saat mengubah gambar: $e");
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFE9EDF6),
      appBar: AppBar(
        title: Text(
          'Detail Pengumuman',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gambarBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        gambarBytes,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(child: Text("Tidak ada gambar")),
                    ),
              SizedBox(height: 15),
              Text(
                pengumuman['judul_pengumuman'] ?? "Tanpa Judul",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    waktuBerlalu(pengumuman['created_at'] ?? ""),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                pengumuman['deskripsi_pengumuman'] ?? "Tidak ada deskripsi",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
