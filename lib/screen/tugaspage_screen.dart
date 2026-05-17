import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/tugas.dart';
import 'dart:convert';
import 'detailtugas_screen.dart';

class TugasSiswaPage extends StatefulWidget {
  @override
  _TugasSiswaPageState createState() => _TugasSiswaPageState();
}

class _TugasSiswaPageState extends State<TugasSiswaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<Tugas> tasks = [];
  List<Tugas> filteredTasks = [];
  String nama = "";
  String namaKelas = "Memuat...";
  String fotoProfil = "";
  String currentTab = 'Semua';
  final String baseUrl = "http://192.168.1.57:8000/";
  bool _isLoading = true;

  // ── Color system selaras HomePage ─────────────────────────────────────────
  static const Color _gradientStart = Color(0xFF1565C0);
  static const Color _gradientMid = Color(0xFF1976D2);
  static const Color _gradientEnd = Color(0xFF64B5F6);

  static const Color _primary = Color(0xFF1976D2);
  static const Color _primaryDark = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFFE3F2FD);

  static const Color _success = Color(0xFF00897B);
  static const Color _successLight = Color(0xFFE0F2F1);
  static const Color _danger = Color(0xFFE53935);
  static const Color _dangerLight = Color(0xFFFFEBEE);
  static const Color _warning = Color(0xFFFB8C00);
  static const Color _warningLight = Color(0xFFFFF3E0);

  static const Color _surface = Color(0xFFF0F4F8);
  static const Color _border = Color(0xFFDDE6EE);
  static const Color _textPrimary = Color(0xFF0D2137);
  static const Color _textSecondary = Color(0xFF607D8B);
  // ─────────────────────────────────────────────────────────────────────────

  final Map<String, Color> _subjectColors = {};
  final List<Color> _availableColors = [
    const Color(0xFF1976D2),
    const Color(0xFF00897B),
    const Color(0xFFFB8C00),
    const Color(0xFFE53935),
    const Color(0xFF0891B2),
    const Color(0xFF7B1FA2),
    const Color(0xFFAD1457),
    const Color(0xFF00838F),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              currentTab = 'Semua';
              break;
            case 1:
              currentTab = 'Belum Dikerjakan';
              break;
            case 2:
              currentTab = 'Selesai';
              break;
          }
        });
        _filterTasks();
      }
    });
    _loadUserData();
    fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('name') ?? "Nama Tidak Ditemukan";
      final fp = prefs.getString('avatar_url') ?? "";
      fotoProfil = fp.isNotEmpty
          ? "${baseUrl}storage/$fp"
          : "https://via.placeholder.com/150";
    });
    final classroomId = prefs.getString('classroom_id');
    if (classroomId != null) _fetchKelas(classroomId);
  }

  Future<void> _fetchKelas(String classroomId) async {
    try {
      final r =
          await http.get(Uri.parse("${baseUrl}api/get-class/$classroomId"));
      if (r.statusCode == 200) {
        setState(() =>
            namaKelas = jsonDecode(r.body)['name'] ?? "Kelas Tidak Ditemukan");
      }
    } catch (_) {
      setState(() => namaKelas = "Gagal Memuat Kelas");
    }
  }

  Future<void> fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final r = await http.get(
        Uri.parse('${baseUrl}api/tugas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (r.statusCode == 200) {
        final List json = jsonDecode(r.body);
        setState(() {
          tasks = json.map((t) => Tugas.fromJson(t)).toList();
          _isLoading = false;
        });
        _filterTasks();
      } else {
        setState(() => _isLoading = false);
        _snack('Gagal memuat tugas: ${r.statusCode}', ok: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Gagal memuat tugas: $e', ok: false);
    }
  }

  bool _isCompleted(Tugas task) {
    final s = task.status?.toLowerCase().trim() ?? '';
    return s == 'submitted' || s == 'sudah dikumpulkan' || s == 'graded';
  }

  void _filterTasks() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final mapel = task.mataPelajaran ?? '';
        final judul = task.judul ?? '';
        final searchMatch =
            mapel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                judul.toLowerCase().contains(_searchQuery.toLowerCase());

        bool statusMatch;
        switch (currentTab) {
          case 'Belum Dikerjakan':
            statusMatch = !_isCompleted(task);
            break;
          case 'Selesai':
            statusMatch = _isCompleted(task);
            break;
          default:
            statusMatch = true;
        }
        return searchMatch && statusMatch;
      }).toList();
    });
  }

  Color _getSubjectColor(String subjectName) {
    if (!_subjectColors.containsKey(subjectName)) {
      _subjectColors[subjectName] =
          _availableColors[_subjectColors.length % _availableColors.length];
    }
    return _subjectColors[subjectName]!;
  }

  bool _isDeadlineOverdue(String deadlineStr) {
    try {
      return DateTime.parse(deadlineStr).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDeadline(String deadlineStr) {
    try {
      final deadline = DateTime.parse(deadlineStr);
      final now = DateTime.now();
      final diff = deadline.difference(now);
      if (diff.isNegative) return 'Tenggat terlewat!';
      if (diff.inDays == 0)
        return 'Hari ini, ${DateFormat('HH:mm').format(deadline)}';
      if (diff.inDays == 1)
        return 'Besok, ${DateFormat('HH:mm').format(deadline)}';
      if (diff.inDays < 7) return '${diff.inDays} hari lagi';
      return DateFormat('dd MMM yyyy, HH:mm').format(deadline);
    } catch (_) {
      return 'Format tanggal tidak valid';
    }
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) return 'Tidak ada tugas yang sesuai pencarian';
    switch (currentTab) {
      case 'Belum Dikerjakan':
        return 'Tidak ada tugas yang belum dikerjakan';
      case 'Selesai':
        return 'Belum ada tugas yang selesai';
      default:
        return 'Belum ada tugas';
    }
  }

  IconData _getEmptyStateIcon() {
    switch (currentTab) {
      case 'Belum Dikerjakan':
        return Icons.assignment_outlined;
      case 'Selesai':
        return Icons.check_circle_outline;
      default:
        return Icons.assignment_late_outlined;
    }
  }

  void _snack(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: ok ? _success : _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ════════════════════════════════════════════════════════
  //  BUILD UTAMA
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _isSearching ? _buildSearchHeader() : _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header gradient biru seperti HomePage ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientMid, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331976D2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: ClipOval(
                  child: fotoProfil.isNotEmpty
                      ? Image.network(
                          fotoProfil,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 26,
                              color: Colors.white),
                        )
                      : const Icon(Icons.person_rounded,
                          size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      namaKelas,
                      style: TextStyle(fontSize: 12, color: Colors.blue[100]),
                    ),
                  ],
                ),
              ),
              // Tombol search
              GestureDetector(
                onTap: () => setState(() => _isSearching = true),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.search_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search header ───────────────────────────────────────────────────────────
  Widget _buildSearchHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientMid, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331976D2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Tombol back
              GestureDetector(
                onTap: () => setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _filterTasks();
                }),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              // Search field
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari tugas atau mata pelajaran...',
                      hintStyle:
                          const TextStyle(fontSize: 14, color: _textSecondary),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: _textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _filterTasks();
                              },
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: _textSecondary),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      _filterTasks();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Tertunda'),
          Tab(text: 'Selesai'),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientMid, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            const Text("Memuat tugas...",
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientMid, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Icon(_getEmptyStateIcon(), size: 42, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              _getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTasks,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailTugasPage(task: task)),
              );
              if (result == true) {
                await fetchTasks();
                _tabController.animateTo(2);
                _snack('Tugas berhasil dikumpulkan!');
              }
            },
            child: buildTaskCard(task),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  TASK CARD
  // ════════════════════════════════════════════════════════
  Widget buildTaskCard(Tugas task) {
    final bool isCompleted = _isCompleted(task);
    final bool isOverdue = _isDeadlineOverdue(task.deadline ?? "");
    final subjectColor = _getSubjectColor(task.mataPelajaran ?? "");

    // ── Status badge config ──────────────────────────────
    IconData statusIcon;
    String statusText;
    Color statusColor;
    Color statusBg;

    if (isCompleted) {
      statusIcon = Icons.check_circle_rounded;
      statusText = task.status?.toLowerCase() == 'graded'
          ? 'Sudah Dinilai'
          : 'Dikumpulkan';
      statusColor = _success;
      statusBg = _successLight;
    } else if (isOverdue) {
      statusIcon = Icons.warning_rounded;
      statusText = 'Tenggat Terlewat';
      statusColor = _danger;
      statusBg = _dangerLight;
    } else {
      statusIcon = Icons.pending_outlined;
      statusText = 'Belum Dikerjakan';
      statusColor = _warning;
      statusBg = _warningLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Side accent bar dengan gradient ──
            Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [subjectColor, subjectColor.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mata pelajaran + chevron
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subjectColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: subjectColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            task.mataPelajaran ?? "—",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: subjectColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chevron_right_rounded,
                              size: 18, color: _textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Judul
                    Text(
                      task.judul ?? "Judul kosong",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Deadline
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            isOverdue && !isCompleted ? _dangerLight : _surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: isOverdue && !isCompleted
                                ? _danger
                                : _textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDeadline(task.deadline ?? ""),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isOverdue && !isCompleted
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isOverdue && !isCompleted
                                  ? _danger
                                  : _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status + nilai
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (task.score != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_gradientMid, _gradientEnd],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: _primary.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.grade_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  "Nilai: ${task.score}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
