import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../model/tugas.dart';

class DetailTugasPage extends StatefulWidget {
  final Tugas task;

  DetailTugasPage({required this.task});

  @override
  _DetailTugasPageState createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage> {
  late Future<Uint8List?> imageBytes;

  @override
  void initState() {
    super.initState();
    imageBytes = _fetchImage(widget.task.imageUrl);
  }

  Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) {
      return null; // Return null instead of throwing exception
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error loading image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(widget.task.judul);
    final bool isDarkColor = _isDarkColor(subjectColor);
    final Color textColor = isDarkColor ? Colors.white : Colors.black87;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with image background
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: subjectColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.task.judul,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              background: FutureBuilder<Uint8List?>(
                future: imageBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                        // Gradient overlay for better text visibility
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Container(
                      color: subjectColor,
                      child: Center(
                        child: Icon(
                          _getSubjectIcon(widget.task.judul),
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  // Aksi untuk edit tugas
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(widget.task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(widget.task.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(widget.task.status),
                          size: 16,
                          color: _getStatusColor(widget.task.status),
                        ),
                        SizedBox(width: 4),
                        Text(
                          widget.task.status,
                          style: TextStyle(
                            color: _getStatusColor(widget.task.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Deskripsi Tugas with section header
                  Text(
                    "DESKRIPSI",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.task.deskripsi,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Teacher info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: subjectColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: subjectColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Guru",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    widget.task.guru,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Divider(height: 24),

                        // Deadline info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: subjectColor.withOpacity(0.2),
                              child: Icon(
                                Icons.calendar_today,
                                color: subjectColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tenggat",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _formatDeadline(widget.task.deadline),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getDeadlineColor(
                                          widget.task.deadline),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Divider(height: 24),

                        // Attachments info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: subjectColor.withOpacity(0.2),
                              child: Icon(
                                Icons.attach_file,
                                color: subjectColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Lampiran",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    "${widget.task.attachments} file",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Button untuk mengerjakan tugas
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Upload Tugas"),
                            content: Text("Fitur ini akan datang segera."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Tutup'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Mengerjakan Tugas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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
        return Colors.blueGrey;
    }
  }

  // Menentukan ikon berdasarkan mata pelajaran
  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'matematika':
        return Icons.calculate;
      case 'bahasa indonesia':
        return Icons.language;
      case 'ipa':
        return Icons.science;
      case 'ips':
        return Icons.public;
      case 'bahasa inggris':
        return Icons.translate;
      case 'pendidikan agama':
        return Icons.menu_book;
      default:
        return Icons.assignment;
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

  // Menentukan ikon status tugas
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sudah dikumpulkan':
        return Icons.check_circle;
      case 'sedang dikerjakan':
        return Icons.pending;
      case 'menunggu':
        return Icons.access_time;
      default:
        return Icons.circle;
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

  // Menentukan warna untuk deadline (merah jika mendekati)
  Color _getDeadlineColor(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration difference = deadline.difference(now);

      if (difference.isNegative) {
        return Colors.red;
      } else if (difference.inDays < 2) {
        return Colors.orange;
      } else {
        return Colors.black87;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // Fungsi untuk menentukan apakah warna gelap atau terang
  bool _isDarkColor(Color color) {
    double luminance =
        0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return luminance < 150;
  }
}
