import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../model/tugas.dart';

class DetailTugasPage extends StatefulWidget {
  final Tugas task;

  // Constructor untuk menerima objek tugas
  DetailTugasPage({required this.task});

  @override
  _DetailTugasPageState createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage> {
  late Future<Uint8List> imageBytes;

  @override
  void initState() {
    super.initState();
    // Ambil gambar saat halaman dibuka
    imageBytes = _fetchImage(widget.task.imageUrl);
  }

  // Fungsi untuk mengambil gambar menggunakan http dan mengembalikannya sebagai byte array
  Future<Uint8List> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) {
      throw Exception("URL gambar tidak valid");
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes; // Mengembalikan gambar dalam bentuk byte array
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(widget.task.judul);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: subjectColor,
        title: Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Aksi untuk mengerjakan tugas atau edit tugas (bisa ditambahkan fungsionalitas lebih lanjut)
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Menampilkan gambar tugas jika ada
            FutureBuilder<Uint8List>(
              future: imageBytes, // Mengambil gambar dengan http
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading image: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return Image.memory(
                      snapshot.data!); // Menampilkan gambar dari byte data
                } else {
                  return Center(child: Text('No image available'));
                }
              },
            ),
            SizedBox(height: 10),
            // Judul Tugas
            Text(
              widget.task.judul,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Deskripsi Tugas
            Text(
              widget.task.deskripsi,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Informasi Tambahan
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  widget.task.guru,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Spacer(),
                Icon(Icons.attach_file, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${widget.task.attachments} lampiran',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Deadline
            Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Tenggat: ${_formatDeadline(widget.task.deadline)}',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Status Tugas
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 18, color: _getStatusColor(widget.task.status)),
                SizedBox(width: 4),
                Text(
                  widget.task.status,
                  style: TextStyle(
                      color: _getStatusColor(widget.task.status), fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Button untuk mengerjakan tugas (misalnya upload tugas)
            ElevatedButton(
              onPressed: () {
                // Fungsi untuk mengerjakan tugas atau mengunggah tugas
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Upload Tugas"),
                    content: Text("Fitur ini akan datang segera."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Tutup'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Mengerjakan Tugas'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    subjectColor, // Menggunakan backgroundColor untuk tombol
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menentukan warna berdasarkan mata pelajaran
  Color _getSubjectColor(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'matematika':
        return Colors.blue;
      case 'bahasa indonesia':
        return Colors.red;
      case 'ipa':
        return Colors.green;
      case 'ips':
        return Colors.orange;
      case 'bahasa inggris':
        return Colors.purple;
      case 'pendidikan agama':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk menentukan warna status tugas
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sudah dikumpulkan':
        return Colors.green;
      case 'sedang dikerjakan':
        return Colors.orange;
      case 'menunggu':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format tenggat waktu tugas
  String _formatDeadline(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration difference = deadline.difference(now);

      if (difference.isNegative) {
        return 'Tenggat terlewat!';
      } else if (difference.inDays == 0) {
        return 'Hari ini, ${DateFormat('HH:mm').format(deadline)}';
      } else if (difference.inDays == 1) {
        return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lagi';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(deadline);
      }
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }
}
