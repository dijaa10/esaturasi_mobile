import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/schedule1.dart';
import '../model/posttest_model.dart';

class PosttestPage extends StatefulWidget {
  final Schedule mapel;
  const PosttestPage({Key? key, required this.mapel}) : super(key: key);

  @override
  _PosttestPageState createState() => _PosttestPageState();
}

class _PosttestPageState extends State<PosttestPage>
    with TickerProviderStateMixin {
  bool _isStarted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  PosttestModel? _posttest;
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _studentId = 0;
  bool _sudahDikerjakan = false;
  Map<String, dynamic>? _hasilSebelumnya;

  final Map<int, String> _jawabanUser = {};

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  // ─── Warna selaras dengan HomePage & PretestPage ─────────────────────────
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
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFDDE6EE);
  static const Color _textPrimary = Color(0xFF0D2137);
  static const Color _textSecondary = Color(0xFF607D8B);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);
    _slideCtrl = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadStudentId();
    _fetchPosttest();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _playTransition() {
    _fadeCtrl.forward(from: 0);
    _slideCtrl.forward(from: 0);
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = prefs.getString('student_id') ?? '0';
    setState(() => _studentId = int.tryParse(idStr) ?? 0);
    debugPrint("DEBUG: Student ID = $_studentId");
  }

  Future<void> _fetchPosttest() async {
    debugPrint("DEBUG: Slug ID = ${widget.mapel.slugId}");
    final String url =
        "${PosttestModel.baseUrl}/api/posttest/slug/${widget.mapel.slugId}";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("Request timeout.");
      });

      debugPrint("DEBUG: Response Status = ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        setState(() {
          _posttest = PosttestModel.fromJson(result['data']);
          _isLoading = false;
        });
        _playTransition();
        await _cekSudahDikerjakan();
      } else {
        setState(() => _isLoading = false);
        _showSnackbar("Gagal memuat data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("DEBUG: Error = $e");
      setState(() => _isLoading = false);
      _showSnackbar("Koneksi error. Pastikan server menyala.");
    }
  }

  Future<void> _cekSudahDikerjakan() async {
    if (_studentId == 0 || _posttest == null) return;
    try {
      final response = await http
          .get(Uri.parse(
              "${PosttestModel.baseUrl}/api/hasil-posttest/$_studentId/${_posttest!.id}"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          setState(() {
            _sudahDikerjakan = true;
            _hasilSebelumnya = result['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("DEBUG cek hasil error: $e");
    }
  }

  Future<void> _submitJawaban() async {
    if (_jawabanUser.length < _posttest!.soal.length) {
      final belum = _posttest!.soal.length - _jawabanUser.length;
      _showSnackbar("Masih ada $belum soal yang belum dijawab!");
      return;
    }
    if (_studentId == 0) {
      _showSnackbar("Session tidak valid. Silakan login ulang.");
      return;
    }
    setState(() => _isSubmitting = true);

    final List<Map<String, dynamic>> jawabanList = _jawabanUser.entries
        .map((e) => {'soal_id': e.key, 'jawaban': e.value})
        .toList();

    try {
      final response = await http
          .post(
            Uri.parse("${PosttestModel.baseUrl}/api/hasil-posttest"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': _studentId,
              'posttest_id': _posttest!.id,
              'jawaban': jawabanList,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        _showHasilDialog(
          nilai: data['nilai'],
          lulus: data['lulus'],
          kkm: data['kkm'],
          benar: data['benar'],
          totalSoal: data['total_soal'],
          pesan: result['message'],
        );
      } else {
        _showSnackbar("Gagal menyimpan: ${result['message']}");
      }
    } catch (e) {
      debugPrint("DEBUG Submit Error = $e");
      _showSnackbar("Koneksi error saat menyimpan hasil.");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ════════════════════════════════════════════════════════
  //  DIALOG HASIL
  // ════════════════════════════════════════════════════════
  void _showHasilDialog({
    required int nilai,
    required bool lulus,
    required int kkm,
    required int benar,
    required int totalSoal,
    required String pesan,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon circle gradient ──
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: lulus
                        ? [_success, Color(0xFF43A047)]
                        : [_danger, Color(0xFFEF5350)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (lulus ? _success : _danger).withOpacity(0.35),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  lulus ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                lulus ? "Selamat, Kamu Lulus! 🎉" : "Tetap Semangat!",
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: _textSecondary, height: 1.5),
              ),
              const SizedBox(height: 26),

              // ── Nilai besar ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: lulus
                        ? [Color(0xFF00897B), Color(0xFF43A047)]
                        : [_danger, Color(0xFFEF5350)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (lulus ? _success : _danger).withOpacity(0.25),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "$nilai",
                      style: const TextStyle(
                        fontSize: 62,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lulus ? "LULUS ✓" : "BELUM LULUS",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Stat pills ──
              Row(
                children: [
                  _statPill(Icons.check_circle_outline_rounded,
                      "$benar/$totalSoal", "Benar", _primary, _primaryLight),
                  const SizedBox(width: 10),
                  _statPill(Icons.flag_outlined, "KKM $kkm", "Minimum",
                      _warning, _warningLight),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tombol selesai ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lulus
                          ? [_success, Color(0xFF43A047)]
                          : [_gradientMid, _gradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (lulus ? _success : _primary).withOpacity(0.35),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Selesai",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(
      IconData icon, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      backgroundColor: _primaryDark,
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
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header gradient biru ────────────────────────────────────────────────
  Widget _buildHeader() {
    final bool inQuiz = _isStarted && !_sudahDikerjakan && _posttest != null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientMid, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331976D2),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, inQuiz ? 8 : 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                          size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inQuiz ? (_posttest?.judul ?? "Kuis") : "Post Test",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (inQuiz)
                          Text(
                            "Soal ${_currentIndex + 1} dari ${_posttest!.soal.length}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[100]),
                          ),
                      ],
                    ),
                  ),
                  if (inQuiz)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        "${_jawabanUser.length}/${_posttest!.soal.length} dijawab",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            if (inQuiz) _buildProgressBar(),
            if (inQuiz) const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        _posttest == null ? 0.0 : (_currentIndex + 1) / _posttest!.soal.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[100],
                      fontWeight: FontWeight.w500)),
              Text("${(progress * 100).toInt()}%",
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_posttest == null) return _buildErrorState();
    if (_sudahDikerjakan && _hasilSebelumnya != null) {
      return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
              position: _slideAnim, child: _buildSudahDikerjakanUI()));
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
          position: _slideAnim,
          child: _isStarted ? _buildQuizUI() : _buildLandingUI()),
    );
  }

  Widget _buildLoadingState() {
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
                    offset: Offset(0, 6))
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const Text("Memuat soal...",
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _dangerLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: _danger.withOpacity(0.15),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child:
                  const Icon(Icons.wifi_off_rounded, size: 40, color: _danger),
            ),
            const SizedBox(height: 18),
            const Text("Data tidak ditemukan",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            const Text("Periksa koneksi dan slug ID kamu.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  LANDING UI
  // ════════════════════════════════════════════════════════
  Widget _buildLandingUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // ── Hero card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gradientMid, _gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded,
                        size: 42, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _posttest!.judul,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    "KKM: ${_posttest!.kkm}",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stat cards ──
          Row(
            children: [
              _infoCard(Icons.help_outline_rounded, "${_posttest!.soal.length}",
                  "Total Soal", _primary, _primaryLight),
              const SizedBox(width: 12),
              _infoCard(Icons.emoji_events_outlined, "${_posttest!.kkm}",
                  "Nilai Min", _warning, _warningLight),
              const SizedBox(width: 12),
              _infoCard(Icons.replay_rounded, "1x", "Percobaan", _success,
                  _successLight),
            ],
          ),
          const SizedBox(height: 20),

          // ── Info notice ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 18, color: _primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Posttest hanya dapat dikerjakan satu kali. Pahami soal dengan seksama dan kerjakan jujur.",
                    style: TextStyle(
                        fontSize: 13, color: _textSecondary, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── Tombol mulai ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientStart, _gradientMid, _gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _isStarted = true);
                  _playTransition();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 24),
                    SizedBox(width: 8),
                    Text("Mulai Sekarang",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
      IconData icon, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  SUDAH DIKERJAKAN UI
  // ════════════════════════════════════════════════════════
  Widget _buildSudahDikerjakanUI() {
    final nilai = _hasilSebelumnya!['nilai'];
    final lulus = _hasilSebelumnya!['lulus'];
    final tanggal = _hasilSebelumnya!['created_at'] ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // ── Status card besar ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: lulus
                    ? [_success, Color(0xFF43A047)]
                    : [_danger, Color(0xFFEF5350)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (lulus ? _success : _danger).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(
                    lulus ? Icons.emoji_events_rounded : Icons.cancel_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$nilai",
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    lulus ? "LULUS ✓" : "BELUM LULUS",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(tanggal,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            lulus
                ? "Kamu sudah lulus posttest ini!"
                : "Posttest sudah dikerjakan",
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary),
          ),
          const SizedBox(height: 16),

          // ── Info lock ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_clock_outlined,
                      size: 18, color: _primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Posttest hanya bisa dikerjakan satu kali dan hasilnya telah tersimpan.",
                    style: TextStyle(
                        fontSize: 13, color: _textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ── Tombol kembali ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientStart, _gradientMid, _gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 20),
                    SizedBox(width: 8),
                    Text("Kembali ke Beranda",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  QUIZ UI
  // ════════════════════════════════════════════════════════
  Widget _buildQuizUI() {
    final soal = _posttest!.soal[_currentIndex];
    _selectedAnswer = _jawabanUser[soal.id];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pertanyaan card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.06),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_gradientMid, _gradientEnd],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Soal ${_currentIndex + 1}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${_posttest!.soal.length - _currentIndex - 1} soal lagi",
                            style: const TextStyle(
                                fontSize: 11, color: _textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 3,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gradientMid, _gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        soal.pertanyaan,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Opsi jawaban ──
                ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                  final i = entry.key;
                  final label = entry.value;
                  final texts = [
                    soal.opsiA,
                    soal.opsiB,
                    soal.opsiC,
                    soal.opsiD
                  ];
                  return _buildOptionCard(label, texts[i], soal.id);
                }),
              ],
            ),
          ),
        ),
        _buildQuizBottomBar(),
      ],
    );
  }

  Widget _buildOptionCard(String label, String text, int soalId) {
    final isSelected = _jawabanUser[soalId] == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAnswer = label;
        _jawabanUser[soalId] = label;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? _primaryLight : _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primary : _border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: _primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_gradientMid, _gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : _surface,
                borderRadius: BorderRadius.circular(11),
                border: isSelected ? null : Border.all(color: _border),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  color: isSelected ? _primaryDark : _textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_gradientMid, _gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom bar quiz ──────────────────────────────────────────────────────
  Widget _buildQuizBottomBar() {
    final isLast = _currentIndex == _posttest!.soal.length - 1;
    final hasMinimap = _posttest!.soal.length > 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Minimap nomor soal ──
            if (hasMinimap) ...[
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _posttest!.soal.length,
                  itemBuilder: (ctx, i) {
                    final sid = _posttest!.soal[i].id;
                    final isDone = _jawabanUser.containsKey(sid);
                    final isCurrent = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _currentIndex = i;
                        _selectedAnswer = _jawabanUser[_posttest!.soal[i].id];
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? const LinearGradient(
                                  colors: [_gradientMid, _gradientEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isCurrent
                              ? null
                              : (isDone ? _primaryLight : _surface),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.transparent
                                : (isDone ? _primary : _border),
                            width: isCurrent ? 0 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                      color: _primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2))
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            "${i + 1}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isCurrent
                                  ? Colors.white
                                  : (isDone ? _primary : _textSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Navigasi ──
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (_currentIndex > 0) ...[
                    GestureDetector(
                      onTap: () => setState(() {
                        _currentIndex--;
                        _selectedAnswer =
                            _jawabanUser[_posttest!.soal[_currentIndex].id];
                      }),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: _textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: _isSubmitting
                          ? Container(
                              decoration: BoxDecoration(
                                color: _primaryLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: _primary, strokeWidth: 3),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLast
                                      ? [_success, Color(0xFF43A047)]
                                      : [
                                          _gradientStart,
                                          _gradientMid,
                                          _gradientEnd
                                        ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLast ? _success : _primary)
                                        .withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isLast) {
                                    _submitJawaban();
                                  } else {
                                    setState(() {
                                      _currentIndex++;
                                      _selectedAnswer = _jawabanUser[
                                          _posttest!.soal[_currentIndex].id];
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isLast ? "Kumpulkan Jawaban" : "Lanjut",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isLast
                                          ? Icons.check_circle_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
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
