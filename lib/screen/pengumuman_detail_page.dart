import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/pengumuman_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PengumumanDetailPage extends StatefulWidget {
  final Pengumuman announcement;

  const PengumumanDetailPage({Key? key, required this.announcement})
      : super(key: key);

  @override
  State<PengumumanDetailPage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<PengumumanDetailPage> {
  bool _isLoading = false;
  late Pengumuman _announcement;
  final String baseUrl = "http://10.0.2.2:8000/";

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;

    // If you need to fetch more detailed data, you can do it here
    // _fetchDetailedAnnouncement();
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();

      // Daftar nama bulan dalam bahasa Indonesia
      final List<String> bulanIndonesia = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      // Format manual: tanggal bulanIndonesia tahun
      return "${date.day} ${bulanIndonesia[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchDetailedAnnouncement() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("${baseUrl}api/pengumuman/${widget.announcement.id}"),
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        setState(() {
          _announcement = Pengumuman.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Gagal mengambil detail: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String _extractTextFromHtml(String htmlString) {
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        elevation: 0,
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and date
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1976D2),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _announcement.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(_announcement.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content (Html content goes here)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Html(
                      data: _announcement.content,
                      onLinkTap: (url, attributes, element) {
                        if (url != null) {
                          print("Link clicked: $url");
                          // Gunakan url_launcher untuk membuka URL
                          launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
