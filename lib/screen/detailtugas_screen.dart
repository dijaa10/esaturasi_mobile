import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../utils/attachment_dialog.dart';
import '../model/tugas.dart';
import '../utils/file_picker_utils.dart';
import '../model/task_service.dart';
import 'dart:io';

class DetailTugasPage extends StatefulWidget {
  final Tugas task;

  DetailTugasPage({required this.task});

  @override
  _DetailTugasPageState createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage> {
  late Future<Uint8List?> imageBytes;
  File? _selectedFile; // simpan file yang dipilih
  late String _status; // variabel status yang bisa diubah dinamis
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    imageBytes = _fetchImage(widget.task.imageUrl);
    _status = widget.task.status ??
        "Belum Dikerjakan"; // inisialisasi dari data tugas
  }

  Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _uploadTask() async {
    showAttachmentOptions();
  }

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Pilih Gambar'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await FilePickerUtil.pickImage();
                  if (file != null) {
                    setState(() {
                      _selectedFile = file;
                    });
                    _showUploadConfirmation(file);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Pilih Dokumen'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await FilePickerUtil.pickDocument();
                  if (file != null) {
                    setState(() {
                      _selectedFile = file;
                    });
                    _showUploadConfirmation(file);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadConfirmation(File file) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Konfirmasi Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah kamu yakin ingin mengirim file ini?'),
              SizedBox(height: 8),
              Text(
                file.path.split('/').last,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            ElevatedButton(
              child: Text('Ya, Upload'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _uploadSelectedFile(file);
    }
  }

  Future<void> _uploadSelectedFile(File file) async {
    // Menampilkan indikator loading
    setState(() {
      _isUploading = true;
    });

    try {
      final taskService = TaskService();
      bool success = await taskService.uploadTaskWithFile(
        tugasId: widget.task.id.toString(),
        siswaId: "1", // sesuaikan kalau bisa dinamis
        file: file,
      );

      // Sembunyikan indikator loading
      setState(() {
        _isUploading = false;
      });

      if (success) {
        setState(() {
          _selectedFile = null;
          _status =
              "Sudah Dikumpulkan"; // Update status dengan format yang konsisten (D besar)
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );

        // Tampilkan dialog konfirmasi
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload tugas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Sembunyikan indikator loading jika terjadi error
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Tugas Berhasil Dikumpulkan')
            ],
          ),
          content: Text(
              'Tugas berhasil dikirim. Status tugas telah diperbarui menjadi "Sudah Dikumpulkan".'),
          actions: [
            TextButton(
              child: Text('Kembali ke Daftar Tugas'),
              onPressed: () {
                // Pop dialog dulu
                Navigator.of(context).pop();
                // Kemudian pop halaman detail dengan result true
                Navigator.pop(context, true);
              },
            ),
            ElevatedButton(
              child: Text('Tetap di Halaman Ini'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(widget.task.judul ?? "");
    final bool isDarkColor = _isDarkColor(subjectColor);
    final Color textColor = isDarkColor ? Colors.white : Colors.black87;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                backgroundColor: subjectColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.task.judul ?? "Detail Tugas",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
                        return Container(color: subjectColor);
                      }
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(_status),
                      SizedBox(height: 20),
                      Text("DESKRIPSI",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(widget.task.deskripsi ?? "Tidak ada deskripsi"),
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                                Icons.person,
                                "Guru",
                                widget.task.guru ?? "Tidak diketahui",
                                subjectColor),
                            Divider(height: 24),
                            _buildInfoRow(
                                Icons.calendar_today,
                                "Tenggat",
                                _formatDeadline(widget.task.deadline ?? ""),
                                subjectColor,
                                valueColor: _getDeadlineColor(
                                    widget.task.deadline ?? "")),
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
                                          content: Text('Tidak ada lampiran')));
                                }
                              },
                              child: _buildInfoRow(
                                  Icons.attach_file,
                                  "Lampiran",
                                  "${widget.task.attachments ?? 0} file",
                                  subjectColor),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      if (_selectedFile != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file,
                                  color: Colors.grey[700]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: subjectColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: Text(
                            _status == 'Sudah Dikumpulkan'
                                ? 'Edit/Mengerjakan Ulang Tugas'
                                : 'Mengerjakan Tugas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Tombol Selesai
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () {
                                  // Kembalikan true jika status adalah "Sudah Dikumpulkan"
                                  Navigator.pop(
                                      context, _status == 'Sudah Dikumpulkan');
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    _isUploading ? Colors.grey : subjectColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isUploading ? Colors.grey : subjectColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Overlay loading saat proses upload
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Mengupload tugas...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    IconData icon = status == 'Sudah Dikumpulkan'
        ? Icons.check_circle
        : Icons.pending_actions;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(status, style: TextStyle(color: color)),
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

  final Map<String, Color> _subjectColors = {};
  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
  ];

  Color _getSubjectColor(String subjectName) {
    if (!_subjectColors.containsKey(subjectName)) {
      _subjectColors[subjectName] =
          _availableColors[_subjectColors.length % _availableColors.length];
    }
    return _subjectColors[subjectName]!;
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

  String _formatDeadline(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration diff = deadline.difference(now);
      if (diff.isNegative) return 'Tenggat terlewat!';
      if (diff.inDays == 0)
        return 'Hari ini, ${DateFormat('HH:mm').format(deadline)}';
      if (diff.inDays == 1)
        return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
      return '${diff.inDays} hari lagi';
    } catch (_) {
      return 'Tanggal tidak valid';
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
