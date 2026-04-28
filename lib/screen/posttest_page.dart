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

class _PosttestPageState extends State<PosttestPage> {
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

  @override
  void initState() {
    super.initState();
    _loadStudentId();
    _fetchPosttest();
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = prefs.getString('student_id') ?? '0';
    setState(() {
      _studentId = int.tryParse(idStr) ?? 0;
    });
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
      debugPrint("DEBUG: Response Body = ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        setState(() {
          _posttest = PosttestModel.fromJson(result['data']);
          _isLoading = false;
        });
        await _cekSudahDikerjakan();
      } else {
        setState(() => _isLoading = false);
        _showSnackbar("Gagal memuat data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("DEBUG: Error = $e");
      setState(() => _isLoading = false);
      _showSnackbar("Koneksi error. Pastikan server Laravel menyala.");
    }
  }

  Future<void> _cekSudahDikerjakan() async {
    if (_studentId == 0 || _posttest == null) return;

    try {
      final response = await http
          .get(Uri.parse(
              "${PosttestModel.baseUrl}/api/hasil-posttest/$_studentId/${_posttest!.id}"))
          .timeout(const Duration(seconds: 10));

      debugPrint("DEBUG cek hasil status = ${response.statusCode}");
      debugPrint("DEBUG cek hasil body = ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          setState(() {
            _sudahDikerjakan = true;
            _hasilSebelumnya = result['data'];
          });
        }
      }
      // 404 = belum pernah dikerjakan, lanjut normal
    } catch (e) {
      debugPrint("DEBUG cek hasil error: $e");
    }
  }

  Future<void> _submitJawaban() async {
    if (_jawabanUser.length < _posttest!.soal.length) {
      final belumDijawab = _posttest!.soal.length - _jawabanUser.length;
      _showSnackbar("Masih ada $belumDijawab soal yang belum dijawab!");
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

      debugPrint("DEBUG Submit Status = ${response.statusCode}");
      debugPrint("DEBUG Submit Body = ${response.body}");

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
        _showSnackbar("Gagal menyimpan hasil: ${result['message']}");
      }
    } catch (e) {
      debugPrint("DEBUG Submit Error = $e");
      _showSnackbar("Koneksi error saat menyimpan hasil.");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              lulus ? Icons.check_circle : Icons.cancel,
              color: lulus ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(lulus ? "Lulus!" : "Belum Lulus"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text(
              "$nilai",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: lulus ? Colors.green : Colors.red,
              ),
            ),
            const Text("Nilai Kamu",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoChip("Benar", "$benar/$totalSoal", Colors.blue),
                _infoChip("KKM", "$kkm", Colors.orange),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lulus ? Colors.green : const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  const Text("Selesai", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        title: Text(_isStarted ? (_posttest?.judul ?? "Kuis") : "Post Test"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Memuat soal posttest..."),
          ],
        ),
      );
    }

    if (_posttest == null) {
      return const Center(
        child: Text(
          "Data Posttest tidak ditemukan.\nCek database slug_id Anda.",
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_sudahDikerjakan && _hasilSebelumnya != null) {
      return _buildSudahDikerjakanUI();
    }

    return _isStarted ? _buildQuizUI() : _buildLandingUI();
  }

  Widget _buildLandingUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(Icons.assignment_turned_in, size: 100, color: Colors.blue),
          const SizedBox(height: 20),
          Text(_posttest!.judul,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Target KKM: ${_posttest!.kkm}",
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 40),
          const Text(
            "Pahami soal dengan seksama dan kerjakan jujur.",
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _isStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("MULAI SEKARANG",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudahDikerjakanUI() {
    final nilai = _hasilSebelumnya!['nilai'];
    final lulus = _hasilSebelumnya!['lulus'];
    final tanggal = _hasilSebelumnya!['created_at'] ?? '-';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            lulus ? Icons.check_circle : Icons.cancel,
            size: 100,
            color: lulus ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            lulus ? "Kamu Sudah Lulus!" : "Posttest Sudah Dikerjakan",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Dikerjakan pada: $tanggal",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            decoration: BoxDecoration(
              color: lulus ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lulus ? Colors.green : Colors.red,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "$nilai",
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: lulus ? Colors.green : Colors.red,
                  ),
                ),
                const Text(
                  "Nilai Kamu",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Posttest hanya bisa dikerjakan satu kali.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "KEMBALI",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizUI() {
    final soal = _posttest!.soal[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  "${_currentIndex + 1} dari ${_posttest!.soal.length}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                Text(
                  soal.pertanyaan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildOption("A", soal.opsiA, soal.id),
          _buildOption("B", soal.opsiB, soal.id),
          _buildOption("C", soal.opsiC, soal.id),
          _buildOption("D", soal.opsiD, soal.id),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _posttest!.soal.length - 1) {
                        setState(() {
                          _currentIndex++;
                          _selectedAnswer =
                              _jawabanUser[_posttest!.soal[_currentIndex].id];
                        });
                      } else {
                        _submitJawaban();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentIndex == _posttest!.soal.length - 1
                          ? "SELESAI"
                          : "LANJUT",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String label, String text, int soalId) {
    bool isSelected = _selectedAnswer == label;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () => setState(() {
          _selectedAnswer = label;
          _jawabanUser[soalId] = label;
        }),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: isSelected ? Colors.blue.shade50 : Colors.white,
          side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text("$label. $text",
            style: const TextStyle(color: Colors.black87)),
      ),
    );
  }
}
