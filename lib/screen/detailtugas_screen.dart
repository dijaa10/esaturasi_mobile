import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../utils/attachment_dialog.dart'; // import modul lampiran
import '../model/tugas.dart';
import '../model/task_service.dart'; // import service untuk task

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
      return null;
    }
    try {
      // Menambahkan timeout
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 10)); // Timeout setelah 10 detik

      // Mengecek jika status code 200 OK
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        print('Gambar tidak ditemukan (404)');
        return null;
      } else {
        print('Error loading image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  // Fungsi untuk mengupload tugas
  Future<void> _uploadTask() async {
    try {
      final taskService = TaskService(); // Pastikan TaskService sudah ada
      bool success = await taskService.uploadTask(widget.task.id.toString());
      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tugas berhasil diupload')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengupload tugas')));
      }
    } catch (e) {
      print('Error uploading task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mengupload tugas')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(widget.task.judul);
    final bool isDarkColor = _isDarkColor(subjectColor);
    final Color textColor = isDarkColor ? Colors.white : Colors.black87;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
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
                        Image.memory(snapshot.data!, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7)
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
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(widget.task.status),
                  SizedBox(height: 20),
                  _buildSectionHeader("DESKRIPSI"),
                  SizedBox(height: 8),
                  Text(widget.task.deskripsi,
                      style: TextStyle(fontSize: 16, height: 1.5)),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, "Guru", widget.task.guru,
                            subjectColor),
                        Divider(height: 24),
                        _buildInfoRow(Icons.calendar_today, "Tenggat",
                            _formatDeadline(widget.task.deadline), subjectColor,
                            valueColor:
                                _getDeadlineColor(widget.task.deadline)),
                        Divider(height: 24),
                        GestureDetector(
                          onTap: () {
                            if (widget.task.imageUrl != null &&
                                widget.task.imageUrl!.isNotEmpty) {
                              showAttachmentDialog(
                                  context, widget.task.imageUrl!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Tidak ada lampiran tersedia')),
                              );
                            }
                          },
                          child: _buildInfoRow(Icons.attach_file, "Lampiran",
                              "${widget.task.attachments} file", subjectColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _uploadTask, // Mengupload tugas
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Mengerjakan Tugas',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status),
              size: 16, color: _getStatusColor(status)),
          SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  color: _getStatusColor(status), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color,
      {Color? valueColor}) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

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

  bool _isDarkColor(Color color) {
    double luminance =
        0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return luminance < 150;
  }
}
