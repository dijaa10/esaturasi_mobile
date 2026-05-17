import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../model/tugas.dart';
import '../model/task_service.dart';
import '../model/submissionstatus.dart';
import '../utils/file_picker_utils.dart';
import '../utils/attachment_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  WARNA SISTEM
// ═══════════════════════════════════════════════════════════════════════════════
class _C {
  static const gradStart = Color(0xFF1565C0);
  static const gradMid = Color(0xFF1976D2);
  static const gradEnd = Color(0xFF64B5F6);

  static const primary = Color(0xFF1976D2);
  static const primaryLight = Color(0xFFE3F2FD);

  static const success = Color(0xFF00897B);
  static const successLight = Color(0xFFE0F2F1);
  static const danger = Color(0xFFE53935);
  static const dangerLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFFB8C00);
  static const warningLight = Color(0xFFFFF3E0);

  static const surface = Color(0xFFF0F4F8);
  static const border = Color(0xFFDDE6EE);
  static const textPrimary = Color(0xFF0D2137);
  static const textSecondary = Color(0xFF607D8B);

  static const imgColor = Color(0xFF1976D2);
  static const imgBg = Color(0xFFE3F2FD);
  static const pdfColor = Color(0xFFE53935);
  static const pdfBg = Color(0xFFFFEBEE);
  static const xlsxColor = Color(0xFF00897B);
  static const xlsxBg = Color(0xFFE0F2F1);
  static const docxColor = Color(0xFFFB8C00);
  static const docxBg = Color(0xFFFFF3E0);
  static const otherColor = Color(0xFF607D8B);
  static const otherBg = Color(0xFFF0F4F8);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MODEL HELPER
// ═══════════════════════════════════════════════════════════════════════════════
class AttachmentFile {
  final String name;
  final String url;
  final String? localPath;

  const AttachmentFile({
    required this.name,
    required this.url,
    this.localPath,
  });

  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  bool get isPdf => extension == 'pdf';
  bool get isExcel => ['xls', 'xlsx'].contains(extension);
  bool get isWord => ['doc', 'docx'].contains(extension);

  Color get typeColor {
    if (isImage) return _C.imgColor;
    if (isPdf) return _C.pdfColor;
    if (isExcel) return _C.xlsxColor;
    if (isWord) return _C.docxColor;
    return _C.otherColor;
  }

  Color get typeBg {
    if (isImage) return _C.imgBg;
    if (isPdf) return _C.pdfBg;
    if (isExcel) return _C.xlsxBg;
    if (isWord) return _C.docxBg;
    return _C.otherBg;
  }

  IconData get typeIcon {
    if (isImage) return Icons.image_rounded;
    if (isPdf) return Icons.picture_as_pdf_rounded;
    if (isExcel) return Icons.table_chart_rounded;
    if (isWord) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String get typeLabel {
    if (isPdf) return 'PDF';
    if (isExcel) return 'XLSX';
    if (isWord) return 'DOCX';
    return extension.toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HALAMAN UTAMA
// ═══════════════════════════════════════════════════════════════════════════════
class DetailTugasPage extends StatefulWidget {
  final Tugas task;
  const DetailTugasPage({Key? key, required this.task}) : super(key: key);

  @override
  State<DetailTugasPage> createState() => _DetailTugasPageState();
}

class _DetailTugasPageState extends State<DetailTugasPage>
    with SingleTickerProviderStateMixin {
  File? _selectedFile;
  String _status = 'Belum Dikerjakan';
  bool _isUploading = false;

  List<AttachmentFile> _submittedFiles = [];
  List<AttachmentFile> _teacherAttachments = [];

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Color _subjectColor;

  static const _palette = [
    Color(0xFF1976D2),
    Color(0xFF00897B),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFF0891B2),
    Color(0xFF7B1FA2),
    Color(0xFFAD1457),
    Color(0xFF00838F),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final idx = (widget.task.judul ?? '').hashCode.abs() % _palette.length;
    _subjectColor = _palette[idx];
    _status = widget.task.status ?? 'Belum Dikerjakan';

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    await Future.wait([
      _loadStatus(),
      _loadSubmittedFiles(),
      _loadTeacherAttachments(),
    ]);
  }

  Future<void> _loadStatus() async {
    final svc = TaskService();
    final SubmissionModel? data =
        await svc.getSubmissionStatus(widget.task.id.toString());
    if (!mounted) return;
    setState(() => _status = data?.statusText ?? 'Belum Dikerjakan');
  }

  Future<void> _loadSubmittedFiles() async {
    try {
      final svc = TaskService();
      final submission =
          await svc.getSubmissionStatus(widget.task.id.toString());
      if (!mounted) return;

      if (submission == null) {
        setState(() => _submittedFiles = []);
        return;
      }

      // filePath dari SubmissionModel — field 'file_path' di API
      const String baseUrl = 'http://192.168.1.57:8000';
      final String path = submission.filePath;

      if (path.isNotEmpty) {
        final url = path.startsWith('http') ? path : '$baseUrl/storage/$path';
        setState(() => _submittedFiles = [
              AttachmentFile(
                name: path.split('/').last,
                url: url,
              )
            ]);
      } else {
        setState(() => _submittedFiles = []);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittedFiles = []);
    }
  }

  Future<void> _loadTeacherAttachments() async {
    if (!mounted) return;
    final imageUrl = widget.task.imageUrl;
    setState(() {
      _teacherAttachments = [
        if (imageUrl != null && imageUrl.isNotEmpty)
          AttachmentFile(name: imageUrl.split('/').last, url: imageUrl),
      ];
    });
  }

  // ── Upload ─────────────────────────────────────────────────────────────────
  void _onUploadTap() {
    HapticFeedback.mediumImpact();
    _showAttachmentPicker();
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachmentPickerSheet(
        onImagePicked: (file) {
          setState(() => _selectedFile = file);
          _showUploadConfirmation(file);
        },
        onDocumentPicked: (file) {
          setState(() => _selectedFile = file);
          _showUploadConfirmation(file);
        },
      ),
    );
  }

  void _showUploadConfirmation(File file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _UploadConfirmDialog(file: file, accentColor: _subjectColor),
    );
    if (ok == true) _doUpload(file);
  }

  Future<void> _doUpload(File file) async {
    setState(() => _isUploading = true);
    try {
      final svc = TaskService();
      final success = await svc.uploadTaskWithFile(
        tugasId: widget.task.id.toString(),
        siswaId: '1',
        file: file,
      );
      if (!mounted) return;
      setState(() => _isUploading = false);
      if (success) {
        await _loadData();
        if (!mounted) return;
        _showSuccess();
        _snack('Tugas berhasil diupload', ok: true);
      } else {
        _snack('Gagal mengupload tugas', ok: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _snack('Terjadi kesalahan: $e', ok: false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => _SuccessDialog(
        accentColor: _subjectColor,
        onBack: () {
          Navigator.of(context).pop();
          Navigator.pop(context, true);
        },
        onStay: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _snack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: ok ? _C.success : _C.danger,
      content: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Badge baris ──────────────────────────────────
                        _buildTopBadges(),
                        const SizedBox(height: 20),

                        // ── Deskripsi ─────────────────────────────────────
                        _buildSectionLabel(
                            'DESKRIPSI', Icons.description_outlined),
                        const SizedBox(height: 8),
                        _buildDescCard(),
                        const SizedBox(height: 20),

                        // ── Detail Tugas ──────────────────────────────────
                        _buildSectionLabel('DETAIL TUGAS', Icons.info_outline),
                        const SizedBox(height: 8),
                        _buildInfoCard(),
                        const SizedBox(height: 20),

                        // ── File yang dipilih (sebelum upload) ────────────
                        if (_selectedFile != null) ...[
                          _buildSectionLabel(
                              'FILE DIPILIH', Icons.attach_file_rounded),
                          const SizedBox(height: 8),
                          _buildSelectedFileCard(),
                          const SizedBox(height: 20),
                        ],

                        // ── Tombol Aksi ───────────────────────────────────
                        _buildGradientButton(
                          label: _status == 'Sudah Dikumpulkan'
                              ? 'Edit / Kumpulkan Ulang'
                              : 'Kumpulkan Tugas',
                          icon: _status == 'Sudah Dikumpulkan'
                              ? Icons.edit_document
                              : Icons.upload_file_rounded,
                          onPressed: _isUploading ? null : _onUploadTap,
                        ),
                        const SizedBox(height: 12),
                        _buildOutlinedButton(
                          label: 'Kembali ke Daftar Tugas',
                          icon: Icons.arrow_back_rounded,
                          onPressed: _isUploading
                              ? null
                              : () => Navigator.pop(
                                  context, _status == 'Sudah Dikumpulkan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  // ── Sliver AppBar dengan hero banner ──────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      stretch: true,
      backgroundColor: _C.gradStart,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context, _status == 'Sudah Dikumpulkan'),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      actions: [
        // Tombol lihat lampiran guru di AppBar jika ada
        if (_teacherAttachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Lampiran Guru',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.attach_file_rounded,
                    color: Colors.white, size: 18),
              ),
              onPressed: _openTeacherAttachments,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
        title: Text(
          widget.task.judul ?? 'Detail Tugas',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.gradStart, _C.gradMid, _C.gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Badges ─────────────────────────────────────────────────────────────
  Widget _buildTopBadges() {
    return Row(
      children: [
        _StatusBadge(status: _status),
        const Spacer(),
        _DeadlineBadge(deadline: widget.task.deadline ?? ''),
      ],
    );
  }

  // ── Deskripsi Card ─────────────────────────────────────────────────────────
  Widget _buildDescCard() {
    final desc = widget.task.deskripsi ?? 'Tidak ada deskripsi.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Text(
        desc,
        style: const TextStyle(
          height: 1.7,
          color: _C.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.school_rounded,
            label: 'Mata Pelajaran',
            value: widget.task.judul ?? '—',
            color: _subjectColor,
          ),
          _divider(),
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Guru',
            value: widget.task.guru ?? 'Tidak diketahui',
            color: _subjectColor,
          ),
          _divider(),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tenggat',
            value: _fmtDeadline(widget.task.deadline ?? ''),
            color: _subjectColor,
            valueColor: _deadlineColor(widget.task.deadline ?? ''),
          ),
          if (widget.task.submittedAt?.isNotEmpty == true) ...[
            _divider(),
            _InfoRow(
              icon: Icons.send_rounded,
              label: 'Dikumpulkan Pada',
              value: _fmtDateTime(widget.task.submittedAt),
              color: _subjectColor,
              valueColor: _C.success,
            ),
          ],
          if (widget.task.score != null) ...[
            _divider(),
            _InfoRow(
              icon: Icons.grade_rounded,
              label: 'Nilai',
              value: '${widget.task.score}',
              color: _subjectColor,
              valueColor: _C.primary,
            ),
          ],
          _divider(),

          // ── Lampiran Guru — bisa di-tap untuk lihat list file ─────────────
          GestureDetector(
            onTap: _teacherAttachments.isEmpty ? null : _openTeacherAttachments,
            child: _InfoRow(
              icon: Icons.attach_file_rounded,
              label: 'Lampiran Guru',
              value: _teacherAttachments.isEmpty
                  ? 'Tidak ada lampiran'
                  : 'Lihat ${_teacherAttachments.length} file',
              color: _subjectColor,
              valueColor: _teacherAttachments.isEmpty ? null : _C.primary,
              trailing: _teacherAttachments.isEmpty
                  ? null
                  : Icon(Icons.chevron_right_rounded,
                      color: _subjectColor, size: 20),
            ),
          ),

          // ── File Tugas Siswa — bisa di-tap untuk lihat list file ──────────
          _divider(),
          GestureDetector(
            onTap: _submittedFiles.isEmpty ? null : _openSubmittedFiles,
            child: _InfoRow(
              icon: Icons.folder_open_rounded,
              label: 'File Tugasmu',
              value: _submittedFiles.isEmpty
                  ? 'Belum ada file dikumpulkan'
                  : 'Lihat ${_submittedFiles.length} file',
              color: _subjectColor,
              valueColor: _submittedFiles.isEmpty ? null : _C.success,
              trailing: _submittedFiles.isEmpty
                  ? null
                  : Icon(Icons.chevron_right_rounded,
                      color: _C.success, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Divider _divider() =>
      const Divider(height: 1, thickness: 1, color: _C.border);

  // ── Selected File Card ─────────────────────────────────────────────────────
  Widget _buildSelectedFileCard() {
    final file = _selectedFile!;
    final af = AttachmentFile(
      name: file.path.split('/').last,
      url: file.path,
      localPath: file.path,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: af.typeColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: af.typeColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: af.typeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(af.typeIcon, color: af.typeColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  af.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _C.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _fileSize(file),
                  style: const TextStyle(fontSize: 11, color: _C.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: _C.dangerLight,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close_rounded, color: _C.danger, size: 16),
            ),
            onPressed: () => setState(() => _selectedFile = null),
          ),
        ],
      ),
    );
  }

  // ── Tombol Gradient ────────────────────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed == null
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [_C.gradStart, _C.gradMid, _C.gradEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ),
    );
  }

  // ── Tombol Outlined ────────────────────────────────────────────────────────
  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final color = onPressed == null ? Colors.grey : _subjectColor;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, color: color, size: 20),
        label: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  // ── Upload Overlay ─────────────────────────────────────────────────────────
  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                      color: _subjectColor, strokeWidth: 5),
                ),
                const SizedBox(height: 20),
                const Text('Mengupload Tugas...',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary)),
                const SizedBox(height: 6),
                const Text('Mohon tunggu sebentar',
                    style: TextStyle(fontSize: 13, color: _C.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _C.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _C.textSecondary,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Buka sheet lampiran guru ───────────────────────────────────────────────
  void _openTeacherAttachments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachmentListSheet(
        title: 'Lampiran Guru',
        files: _teacherAttachments,
        onPreview: _openFilePreview,
      ),
    );
  }

  // ── Buka sheet file yang sudah dikumpulkan ────────────────────────────────
  void _openSubmittedFiles() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmittedFilesSheet(
        files: _submittedFiles,
        onPreview: _openFilePreview,
        onDelete: (file) async {
          // TODO: panggil API hapus file di sini
          // await TaskService().deleteSubmittedFile(fileId);
          setState(() => _submittedFiles.remove(file));
          _snack('File dihapus', ok: true);
        },
      ),
    );
    // Reload setelah sheet ditutup agar info card sinkron
    _loadSubmittedFiles();
  }

  // ── Buka preview file ──────────────────────────────────────────────────────
  void _openFilePreview(AttachmentFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilePreviewSheet(file: file),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtDeadline(String s) {
    try {
      final d = DateTime.parse(s);
      final diff = d.difference(DateTime.now());
      if (diff.isNegative)
        return 'Terlewat! (${DateFormat('dd MMM yyyy').format(d)})';
      if (diff.inDays == 0) return 'Hari ini, ${DateFormat('HH:mm').format(d)}';
      if (diff.inDays == 1) return 'Besok, ${DateFormat('HH:mm').format(d)}';
      if (diff.inDays < 7) return '${diff.inDays} hari lagi';
      return DateFormat('dd MMM yyyy, HH:mm').format(d);
    } catch (_) {
      return 'Tanggal tidak valid';
    }
  }

  String _fmtDateTime(String? s) {
    if (s == null || s.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  Color _deadlineColor(String s) {
    try {
      final diff = DateTime.parse(s).difference(DateTime.now());
      if (diff.isNegative) return _C.danger;
      if (diff.inDays < 2) return _C.warning;
      return _C.success;
    } catch (_) {
      return _C.textSecondary;
    }
  }

  String _fileSize(File f) {
    try {
      final b = f.lengthSync();
      if (b < 1024) return '$b B';
      if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Attachment List Sheet (dipakai untuk guru & siswa)
// ═══════════════════════════════════════════════════════════════════════════════
class _AttachmentListSheet extends StatelessWidget {
  final String title;
  final List<AttachmentFile> files;
  final void Function(AttachmentFile) onPreview;

  const _AttachmentListSheet({
    required this.title,
    required this.files,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${files.length} file',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // File list
          ...files.map((f) => _AttachmentRow(
                file: f,
                onTap: () {
                  Navigator.pop(context);
                  onPreview(f);
                },
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Submitted Files Sheet (file tugas siswa — bisa preview & hapus)
// ═══════════════════════════════════════════════════════════════════════════════
class _SubmittedFilesSheet extends StatefulWidget {
  final List<AttachmentFile> files;
  final void Function(AttachmentFile) onPreview;
  final void Function(AttachmentFile) onDelete;

  const _SubmittedFilesSheet({
    required this.files,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  State<_SubmittedFilesSheet> createState() => _SubmittedFilesSheetState();
}

class _SubmittedFilesSheetState extends State<_SubmittedFilesSheet> {
  late List<AttachmentFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  void _confirmDelete(AttachmentFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus File?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'File "${file.name}" akan dihapus dari pengumpulan.',
          style: const TextStyle(color: _C.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _files.remove(file));
      widget.onDelete(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File Tugasmu',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap file untuk preview, tahan untuk hapus',
                      style: TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_files.length} file',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.folder_off_rounded,
                      size: 48, color: _C.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 10),
                  const Text(
                    'Semua file telah dihapus',
                    style: TextStyle(color: _C.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ..._files.map((f) => _SubmittedFileRow(
                  file: f,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPreview(f);
                  },
                  onDelete: () => _confirmDelete(f),
                )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Submitted File Row (dengan tombol hapus)
// ═══════════════════════════════════════════════════════════════════════════════
class _SubmittedFileRow extends StatelessWidget {
  final AttachmentFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubmittedFileRow({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            // Ikon tipe file
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: file.typeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(file.typeIcon, color: file.typeColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info file
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _C.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: file.typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          file.typeLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: file.typeColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: _C.success),
                      const SizedBox(width: 3),
                      const Text(
                        'Sudah dikumpulkan',
                        style: TextStyle(
                            fontSize: 10,
                            color: _C.success,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tombol aksi
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility_rounded,
                        color: _C.primary, size: 16),
                  ),
                  onPressed: onTap,
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _C.danger, size: 16),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Attachment Row
// ═══════════════════════════════════════════════════════════════════════════════
class _AttachmentRow extends StatelessWidget {
  final AttachmentFile file;
  final VoidCallback onTap;

  const _AttachmentRow({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: file.typeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(file.typeIcon, color: file.typeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _C.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: file.typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      file.typeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: file.typeColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.visibility_rounded, color: _C.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: File Preview Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class _FilePreviewSheet extends StatefulWidget {
  final AttachmentFile file;
  const _FilePreviewSheet({required this.file});

  @override
  State<_FilePreviewSheet> createState() => _FilePreviewSheetState();
}

class _FilePreviewSheetState extends State<_FilePreviewSheet> {
  Uint8List? _imageBytes;
  bool _loadingImage = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.file.isImage) _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => _loadingImage = true);
    try {
      if (widget.file.localPath != null) {
        _imageBytes = await File(widget.file.localPath!).readAsBytes();
      } else if (widget.file.url.isNotEmpty) {
        final r = await http.get(Uri.parse(widget.file.url));
        if (r.statusCode == 200) _imageBytes = r.bodyBytes;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingImage = false);
  }

  // ── Download ───────────────────────────────────────────────────────────────
  Future<void> _onDownload() async {
    if (_isDownloading) return;

    // 1. Minta izin storage
    final granted = await _requestStoragePermission();
    if (!granted) {
      if (!mounted) return;
      _showSnack('Izin penyimpanan ditolak', ok: false);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final dio = Dio();
      final fileName = widget.file.name;
      final String savePath;

      if (Platform.isAndroid) {
        // Android: simpan ke /storage/emulated/0/Download
        Directory? dlDir;
        try {
          dlDir = Directory('/storage/emulated/0/Download');
          if (!await dlDir.exists())
            dlDir = await getExternalStorageDirectory();
        } catch (_) {
          dlDir = await getExternalStorageDirectory();
        }
        savePath = '${dlDir!.path}/$fileName';
      } else {
        // iOS: simpan ke Documents
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName';
      }

      await dio.download(
        widget.file.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });

      // 2. Buka file setelah diunduh
      _showSnack('Tersimpan di folder Download ✓', ok: true);
      await Future.delayed(const Duration(milliseconds: 600));
      await OpenFile.open(savePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
      _showSnack('Gagal mengunduh: $e', ok: false);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) return true;

    // Android 13+ (SDK 33) tidak perlu WRITE_EXTERNAL_STORAGE
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 33) {
      // Untuk gambar, cek Photos permission; untuk file lain tidak perlu izin
      if (widget.file.isImage) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return true;
    }

    // Android < 13 perlu WRITE_EXTERNAL_STORAGE
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }

  void _showSnack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      backgroundColor: ok ? _C.success : _C.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.file.typeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.file.typeIcon,
                    color: widget.file.typeColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.file.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _C.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration:
                      BoxDecoration(color: _C.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: _C.textSecondary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewContent(),
          const SizedBox(height: 16),
          // ── Tombol Unduh ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.file.typeColor,
                disabledBackgroundColor: widget.file.typeColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _isDownloading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.download_rounded, color: Colors.white),
              label: Text(
                _isDownloading
                    ? _downloadProgress > 0
                        ? 'Mengunduh ${(_downloadProgress * 100).toInt()}%...'
                        : 'Mengunduh...'
                    : 'Unduh File',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (widget.file.isImage) {
      if (_loadingImage) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: _C.primary),
        );
      }
      if (_imageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
            height: 260,
            width: double.infinity,
          ),
        );
      }
      return _previewUnavailable('Gambar tidak dapat dimuat');
    }

    if (widget.file.isPdf) {
      return _PdfPreviewPlaceholder(
          url: widget.file.url, localPath: widget.file.localPath);
    }

    return _OfficePreviewPlaceholder(file: widget.file);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: PDF Preview Placeholder
// ═══════════════════════════════════════════════════════════════════════════════
class _PdfPreviewPlaceholder extends StatefulWidget {
  final String url;
  final String? localPath;
  const _PdfPreviewPlaceholder({required this.url, this.localPath});

  @override
  State<_PdfPreviewPlaceholder> createState() => _PdfPreviewPlaceholderState();
}

class _PdfPreviewPlaceholderState extends State<_PdfPreviewPlaceholder> {
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.localPath == null) _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_downloading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: _C.pdfColor),
            SizedBox(height: 12),
            Text('Memuat PDF...',
                style: TextStyle(color: _C.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _C.pdfBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.picture_as_pdf_rounded, color: _C.pdfColor, size: 56),
          SizedBox(height: 10),
          Text('Preview PDF',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _C.textPrimary)),
          SizedBox(height: 4),
          Text(
            'Install flutter_pdfview untuk\nmelihat isi PDF langsung',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Office Preview Placeholder
// ═══════════════════════════════════════════════════════════════════════════════
class _OfficePreviewPlaceholder extends StatelessWidget {
  final AttachmentFile file;
  const _OfficePreviewPlaceholder({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: file.typeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(file.typeIcon, color: file.typeColor, size: 52),
          const SizedBox(height: 10),
          Text(
            file.isExcel ? 'File Excel' : 'File Word',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: _C.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unduh untuk membuka di aplikasi lain',
            style: TextStyle(color: _C.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Widget _previewUnavailable(String msg) {
  return Container(
    height: 160,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_rounded,
            color: _C.textSecondary, size: 44),
        const SizedBox(height: 8),
        Text(msg,
            style: const TextStyle(color: _C.textSecondary, fontSize: 13)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Attachment Picker Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class _AttachmentPickerSheet extends StatelessWidget {
  final void Function(File) onImagePicked;
  final void Function(File) onDocumentPicked;

  const _AttachmentPickerSheet({
    required this.onImagePicked,
    required this.onDocumentPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Text(
                'Unggah File Tugas',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PickerOption(
                    icon: Icons.image_rounded,
                    label: 'Gambar',
                    bg: _C.imgBg,
                    color: _C.imgColor,
                    onTap: () async {
                      Navigator.pop(context);
                      final f = await FilePickerUtil.pickImage();
                      if (f != null) onImagePicked(f);
                    },
                  ),
                  _PickerOption(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    bg: _C.pdfBg,
                    color: _C.pdfColor,
                    onTap: () async {
                      Navigator.pop(context);
                      final f = await FilePickerUtil.pickDocument();
                      if (f != null) onDocumentPicked(f);
                    },
                  ),
                  _PickerOption(
                    icon: Icons.table_chart_rounded,
                    label: 'Excel',
                    bg: _C.xlsxBg,
                    color: _C.xlsxColor,
                    onTap: () async {
                      Navigator.pop(context);
                      final f = await FilePickerUtil.pickDocument();
                      if (f != null) onDocumentPicked(f);
                    },
                  ),
                  _PickerOption(
                    icon: Icons.description_rounded,
                    label: 'Word',
                    bg: _C.docxBg,
                    color: _C.docxColor,
                    onTap: () async {
                      Navigator.pop(context);
                      final f = await FilePickerUtil.pickDocument();
                      if (f != null) onDocumentPicked(f);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Upload Confirm Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _UploadConfirmDialog extends StatelessWidget {
  final File file;
  final Color accentColor;

  const _UploadConfirmDialog({required this.file, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final af = AttachmentFile(name: file.path.split('/').last, url: file.path);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, size: 56, color: accentColor),
            const SizedBox(height: 14),
            const Text('Konfirmasi Pengumpulan',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Apakah kamu yakin ingin mengirim file berikut?',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Icon(af.typeIcon, color: af.typeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      af.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _C.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya, Kirim',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Success Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _SuccessDialog extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onStay;

  const _SuccessDialog({
    required this.accentColor,
    required this.onBack,
    required this.onStay,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _C.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _C.success, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tugas Berhasil Dikumpulkan!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Status tugas telah diperbarui menjadi "Sudah Dikumpulkan".',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: onBack,
                    child: const Text('Kembali'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    onPressed: onStay,
                    child: const Text('Tetap di Sini',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Info Row
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? _C.textPrimary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Status Badge
// ═══════════════════════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;

    switch (status.toLowerCase()) {
      case 'sudah dikumpulkan':
      case 'submitted':
        color = _C.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'graded':
        color = _C.primary;
        icon = Icons.grade_rounded;
        break;
      case 'sedang dikerjakan':
        color = _C.warning;
        icon = Icons.hourglass_top_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.pending_actions_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(status,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGET: Deadline Badge
// ═══════════════════════════════════════════════════════════════════════════════
class _DeadlineBadge extends StatelessWidget {
  final String deadline;
  const _DeadlineBadge({required this.deadline});

  @override
  Widget build(BuildContext context) {
    try {
      final d = DateTime.parse(deadline);
      final diff = d.difference(DateTime.now());
      late Color color;
      late IconData icon;
      late String text;

      if (diff.isNegative) {
        color = _C.danger;
        icon = Icons.warning_amber_rounded;
        text = 'Terlewat';
      } else if (diff.inDays == 0) {
        color = _C.warning;
        icon = Icons.today_rounded;
        text = 'Hari Ini';
      } else if (diff.inDays == 1) {
        color = _C.warning;
        icon = Icons.hourglass_top_rounded;
        text = 'Besok';
      } else if (diff.inDays < 7) {
        color = _C.success;
        icon = Icons.event_rounded;
        text = '${diff.inDays} Hari';
      } else {
        color = _C.success;
        icon = Icons.date_range_rounded;
        text = '${(diff.inDays / 7).floor()} Minggu';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
