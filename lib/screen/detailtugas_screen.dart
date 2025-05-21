import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import '../utils/attachment_dialog.dart';
import '../model/tugas.dart';
import '../utils/file_picker_utils.dart';
import '../model/task_service.dart';
import '../model/submissionstatus.dart';
import 'package:flutter/services.dart';

class DetailTugasPage extends StatefulWidget {
  final Tugas task;

  DetailTugasPage({required this.task});

  @override
  _DetailTugasPageState createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage>
    with SingleTickerProviderStateMixin {
  late Future<Uint8List?> imageBytes;
  File? _selectedFile;
  late String _status;
  bool _isUploading = false;

  // Animasi untuk detail
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    imageBytes = _fetchImage(widget.task.imageUrl);
    _status = widget.task.status ?? "Belum Dikerjakan";
    _loadLatestStatus();

    // Inisialisasi animasi
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestStatus() async {
    final taskService = TaskService();
    final SubmissionModel? statusData =
        await taskService.getSubmissionStatus(widget.task.id.toString());
    if (statusData != null && mounted) {
      setState(() {
        _status = statusData.statusText;
      });
    } else if (mounted) {
      setState(() {
        _status = "Status tidak tersedia";
      });
    }
  }

  Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadTask() async {
    // Berikan feedback haptic untuk interaksi
    HapticFeedback.mediumImpact();
    showAttachmentOptions();
  }

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 5,
                )
              ]),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 16, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Text(
                    "Unggah File Tugas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentOption(ctx, Icons.image_rounded, "Gambar",
                          Colors.blue.shade100, Colors.blue, () async {
                        Navigator.pop(ctx);
                        final file = await FilePickerUtil.pickImage();
                        if (file != null) {
                          setState(() => _selectedFile = file);
                          _showUploadConfirmation(file);
                        }
                      }),
                      _buildAttachmentOption(ctx, Icons.picture_as_pdf_rounded,
                          "Dokumen", Colors.red.shade100, Colors.red, () async {
                        Navigator.pop(ctx);
                        final file = await FilePickerUtil.pickDocument();
                        if (file != null) {
                          setState(() => _selectedFile = file);
                          _showUploadConfirmation(file);
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(BuildContext context, IconData icon,
      String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showUploadConfirmation(File file) async {
    final Color subjectColor = _getSubjectColor(widget.task.judul ?? "");
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 60,
                  color: subjectColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Konfirmasi Pengumpulan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Apakah kamu yakin ingin mengirim file berikut:'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(_getFileIcon(file.path), color: subjectColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.path.split('/').last,
                          style: TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Batal'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subjectColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Ya, Kirim',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _uploadSelectedFile(file);
    }
  }

  IconData _getFileIcon(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return Icons.image;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Future<void> _uploadSelectedFile(File file) async {
    setState(() => _isUploading = true);
    try {
      final taskService = TaskService();
      bool success = await taskService.uploadTaskWithFile(
        tugasId: widget.task.id.toString(),
        siswaId: "1", // ganti nanti sesuai user login
        file: file,
      );

      setState(() => _isUploading = false);

      if (success) {
        final statusData =
            await taskService.getSubmissionStatus(widget.task.id.toString());
        setState(() {
          _selectedFile = null;
          _status = statusData?.statusText ?? "Status tidak tersedia";
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Tugas berhasil diupload'),
            ],
          ),
          backgroundColor: Colors.green,
        ));
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Gagal mengupload tugas'),
            ],
          ),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Terjadi kesalahan: ${e.toString()}')),
          ],
        ),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showSuccessDialog() {
    final Color subjectColor = _getSubjectColor(widget.task.judul ?? "");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Tugas Berhasil Dikumpulkan!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Selamat! Tugas berhasil dikirim. Status tugas telah diperbarui menjadi "Sudah Dikumpulkan".',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.pop(context, true);
                      },
                      child: Text('Kembali'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Tetap di Sini',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor(widget.task.judul ?? "");
    final bool isDarkColor = _isDarkColor(subjectColor);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: subjectColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () =>
                      Navigator.pop(context, _status == 'Sudah Dikumpulkan'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      EdgeInsets.only(left: 16, bottom: 16, right: 16),
                  title: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Text(
                      widget.task.judul ?? "Detail Tugas",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List?>(
                        future: imageBytes,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(snapshot.data!,
                                fit: BoxFit.cover);
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                color: subjectColor,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    subjectColor,
                                    subjectColor.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Icon(
                                _getSubjectIcon(widget.task.judul ?? ""),
                                color: Colors.white.withOpacity(0.2),
                                size: 120,
                              ),
                            );
                          }
                        },
                      ),
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
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(_status),
                            Spacer(),
                            _buildDeadlineBadge(widget.task.deadline ?? ""),
                          ],
                        ),
                        SizedBox(height: 24),
                        _buildSectionTitle(
                            "DESKRIPSI", Icons.description_outlined),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.task.deskripsi ?? "Tidak ada deskripsi",
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        _buildSectionTitle("DETAIL TUGAS", Icons.info_outline),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                  Icons.school,
                                  "Mata Pelajaran",
                                  widget.task.judul ?? "Tidak tersedia",
                                  subjectColor),
                              Divider(height: 24, thickness: 1),
                              _buildInfoRow(
                                  Icons.person,
                                  "Guru",
                                  widget.task.guru ?? "Tidak diketahui",
                                  subjectColor),
                              Divider(height: 24, thickness: 1),
                              _buildInfoRow(
                                Icons.calendar_today,
                                "Tenggat",
                                _formatDeadline(widget.task.deadline ?? ""),
                                subjectColor,
                                valueColor: _getDeadlineColor(
                                    widget.task.deadline ?? ""),
                              ),
                              Divider(height: 24, thickness: 1),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  if (widget.task.imageUrl != null &&
                                      widget.task.imageUrl!.isNotEmpty) {
                                    showAttachmentDialog(
                                        context, widget.task.imageUrl!);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Tidak ada lampiran'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: _buildInfoRow(
                                  Icons.attach_file,
                                  "Lampiran",
                                  "Lihat ${widget.task.attachments ?? 0} file",
                                  subjectColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        if (_selectedFile != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "FILE YANG DIPILIH",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: subjectColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getFileIcon(_selectedFile!.path),
                                        color: subjectColor,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFile!.path.split('/').last,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _getFileSize(_selectedFile!),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                      onPressed: () =>
                                          setState(() => _selectedFile = null),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        _buildGradientButton(
                          label: _status == 'Sudah Dikumpulkan'
                              ? 'Edit/Mengerjakan Ulang Tugas'
                              : 'Mengerjakan Tugas',
                          icon: _status == 'Sudah Dikumpulkan'
                              ? Icons.edit_document
                              : Icons.upload_file,
                          color: subjectColor,
                          onPressed: _isUploading ? null : _uploadTask,
                        ),
                        SizedBox(height: 16),
                        _buildOutlinedButton(
                          label: 'Kembali ke Daftar Tugas',
                          icon: Icons.arrow_back,
                          color: subjectColor,
                          onPressed: _isUploading
                              ? null
                              : () => Navigator.pop(
                                  context, _status == 'Sudah Dikumpulkan'),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading) _buildUploadingOverlay(subjectColor),
        ],
      ),
    );
  }

  Widget _buildUploadingOverlay(Color color) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 6,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Mengupload Tugas...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    IconData icon = Icons.pending_actions;

    if (status.toLowerCase() == 'sudah dikumpulkan') {
      icon = Icons.check_circle;
    } else if (status.toLowerCase() == 'sedang dikerjakan') {
      icon = Icons.hourglass_top;
    } else if (status.toLowerCase() == 'menunggu') {
      icon = Icons.watch_later;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBadge(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      Duration diff = deadline.difference(DateTime.now());
      Color color = _getDeadlineColor(deadlineStr);
      String text;
      IconData icon;

      if (diff.isNegative) {
        text = 'Terlewat';
        icon = Icons.warning_amber_rounded;
      } else if (diff.inDays == 0) {
        text = 'Hari Ini';
        icon = Icons.today;
      } else if (diff.inDays == 1) {
        text = 'Besok';
        icon = Icons.hourglass_top;
      } else if (diff.inDays < 7) {
        text = '${diff.inDays} Hari';
        icon = Icons.event;
      } else {
        text = '${(diff.inDays / 7).floor()} Minggu';
        icon = Icons.date_range;
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return Container();
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: onPressed == null
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [color, color.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null ? Colors.grey : color,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: onPressed == null ? Colors.grey : color,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null ? Colors.grey : color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final Map<String, Color> _subjectColors = {};
  final Map<String, IconData> _subjectIcons = {};

  final List<Color> _availableColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
  ];

  final List<IconData> _availableIcons = [
    Icons.auto_stories,
    Icons.science,
    Icons.calculate,
    Icons.language,
    Icons.history_edu,
    Icons.sports_soccer,
    Icons.brush,
    Icons.music_note,
  ];

  Color _getSubjectColor(String subjectName) {
    if (!_subjectColors.containsKey(subjectName)) {
      _subjectColors[subjectName] =
          _availableColors[_subjectColors.length % _availableColors.length];
    }
    return _subjectColors[subjectName]!;
  }

  IconData _getSubjectIcon(String subjectName) {
    if (!_subjectIcons.containsKey(subjectName)) {
      _subjectIcons[subjectName] =
          _availableIcons[_subjectIcons.length % _availableIcons.length];
    }
    return _subjectIcons[subjectName]!;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sudah dikumpulkan':
        return Color(0xFF4CAF50); // Green
      case 'sedang dikerjakan':
        return Color(0xFFFF9800); // Orange
      case 'menunggu':
        return Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  String _formatDeadline(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration diff = deadline.difference(now);

      final DateFormat dateFormat = DateFormat('dd MMM yyyy');
      final DateFormat timeFormat = DateFormat('HH:mm');

      if (diff.isNegative) {
        return 'Terlewat! (${dateFormat.format(deadline)})';
      }

      if (diff.inDays == 0) {
        return 'Hari ini, ${timeFormat.format(deadline)}';
      }

      if (diff.inDays == 1) {
        return 'Besok, ${timeFormat.format(deadline)}';
      }

      if (diff.inDays < 7) {
        return '${diff.inDays} hari lagi (${dateFormat.format(deadline)})';
      }

      return '${dateFormat.format(deadline)}, ${timeFormat.format(deadline)}';
    } catch (_) {
      return 'Tanggal tidak valid';
    }
  }

  Color _getDeadlineColor(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      Duration diff = deadline.difference(DateTime.now());

      if (diff.isNegative) {
        return Color(0xFFF44336); // Red
      }

      if (diff.inDays < 2) {
        return Color(0xFFFF9800); // Orange
      }

      return Color(0xFF4CAF50); // Green
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  bool _isDarkColor(Color color) {
    double luminance =
        0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return luminance < 150;
  }
}
