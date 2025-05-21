import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/announcement.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class Announcementdetailpage extends StatefulWidget {
  final Announcement announcement;

  const Announcementdetailpage({Key? key, required this.announcement})
      : super(key: key);

  @override
  State<Announcementdetailpage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<Announcementdetailpage> {
  bool _isLoading = false;
  late Announcement _announcement;
  final String baseUrl = "https://esaturasi.my.id/";

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
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
        Uri.parse("${baseUrl}api/announcement/${widget.announcement.id}"),
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        setState(() {
          _announcement = Announcement.fromJson(data);
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
        title: const Text(
          'Detail Pengumuman',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _announcement.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Color(0xFF64B5F6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(_announcement.date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFEEEEEE)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Html(
                        data: _announcement.content,
                        style: {
                          "body": Style(
                            fontSize: FontSize(15.0),
                            lineHeight: LineHeight(1.5),
                            margin: Margins.zero,
                            padding: HtmlPaddings.only(bottom: 10000),
                          ),
                          "a": Style(
                            color: const Color(0xFF1976D2),
                          ),
                        },
                        onLinkTap: (url, attributes, element) {
                          if (url != null) {
                            launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
