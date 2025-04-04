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
  final String baseUrl = "http://127.0.0.1:8000/";

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

  Future<void> _shareAnnouncement() async {
    final String content =
        "Pengumuman: ${_announcement.title}\n\n${_extractTextFromHtml(_announcement.content)}\n\nTanggal: ${_formatDate(_announcement.date)}";

    await Share.share(content, subject: _announcement.title);
  }

  String _extractTextFromHtml(String htmlContent) {
    return htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
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

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Html(
                      data: _announcement.content,
                      style: {
                        "body": Style(
                          fontSize: FontSize(15),
                          lineHeight: LineHeight(1.5),
                        ),
                        "a": Style(
                          color: const Color(0xFF1976D2),
                          textDecoration: TextDecoration.none,
                        ),
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url != null) {
                          // Handle the URL opening - you might want to use url_launcher package
                          print("Link clicked: $url");
                          // Add url_launcher implementation here
                          // launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  ),

                  // Additional info or metadata if available
                  if (_announcement.author != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              color: Color(0xFF757575), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Ditulis oleh: ${_announcement.author}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
