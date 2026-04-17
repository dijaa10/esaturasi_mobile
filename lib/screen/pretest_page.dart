import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/schedule1.dart';
import '../model/pretest_model.dart';

class PretestPage extends StatefulWidget {
  final Schedule mapel;
  const PretestPage({Key? key, required this.mapel}) : super(key: key);

  @override
  _PretestPageState createState() => _PretestPageState();
}

class _PretestPageState extends State<PretestPage> {
  bool _isStarted = false;
  bool _isLoading = true;
  PretestModel? _pretest;
  int _currentIndex = 0;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _fetchPretest();
  }

  Future<void> _fetchPretest() async {
    // Debug ID sebelum panggil API
    debugPrint("DEBUG: Slug ID yang dikirim = ${widget.mapel.slugId}");

    final String url =
        "${PretestModel.baseUrl}/api/pretest/slug/${widget.mapel.slugId}";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10), onTimeout: () {
        // ← tambah timeout
        throw Exception("Request timeout. Server terlalu lama merespons.");
      });

      debugPrint("DEBUG: Response Status = ${response.statusCode}");
      debugPrint("DEBUG: Response Body = ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        setState(() {
          _pretest = PretestModel.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackbar("Gagal memuat data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("DEBUG: Terjadi Error = $e");
      setState(() => _isLoading = false);
      _showSnackbar("Koneksi error. Pastikan server Laravel menyala.");
      _showSnackbar("Koneksi timeout. Coba lagi.");
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      appBar: AppBar(
        title: Text(_isStarted ? (_pretest?.judul ?? "Kuis") : "Pre Test"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_pretest == null) {
      return const Center(
        child: Text("Data Pretest tidak ditemukan.\nCek database slug_id Anda.",
            textAlign: TextAlign.center),
      );
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
          const Icon(Icons.assignment_turned_in,
              size: 100, color: Colors.orange),
          const SizedBox(height: 20),
          Text(_pretest!.judul,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Target KKM: ${_pretest!.kkm}",
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 40),
          const Text("Pahami soal dengan seksama dan kerjakan jujur.",
              textAlign: TextAlign.center),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _isStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
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

  Widget _buildQuizUI() {
    final soal = _pretest!.soal[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text("${_currentIndex + 1} dari ${_pretest!.soal.length}",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 15),
                Text(soal.pertanyaan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildOption("A", soal.opsiA),
          _buildOption("B", soal.opsiB),
          _buildOption("C", soal.opsiC),
          _buildOption("D", soal.opsiD),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_currentIndex < _pretest!.soal.length - 1) {
                  setState(() {
                    _currentIndex++;
                    _selectedAnswer = null;
                  });
                } else {
                  _showSnackbar("Pretest Selesai!");
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2)),
              child: Text(
                  _currentIndex == _pretest!.soal.length - 1
                      ? "SELESAI"
                      : "LANJUT",
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String label, String text) {
    bool isSelected = _selectedAnswer == label;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedAnswer = label),
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
