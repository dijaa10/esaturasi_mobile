import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/announcement.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    _fetchDetailedAnnouncement();
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //       content: Text("Gagal mengambil detail: ${response.statusCode}")),
        // );
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
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900, // Extra bold
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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
              color: Colors.grey[100],
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 16, bottom: 240),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      width: 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Decorative top line element - EXACTLY same as card
                        Container(
                          height: 3,
                          width: 60,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _announcement.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17, // Exact match with card
                                  color: Color(0xFF1E3A5F),
                                  letterSpacing: 0.2,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1976D2).withOpacity(0.85),
                                    const Color(0xFF42A5F5).withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2)
                                        .withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(_announcement.date),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14), // Exact match with card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12), // Exact match with card
                          decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[100]!,
                                width: 0.8,
                              )),
                          child: Html(
                            data: _announcement.content,
                            style: {
                              "body": Style(
                                fontSize:
                                    FontSize(14.0), // Exact match with card
                                lineHeight: LineHeight(1.5),
                                margin: Margins.zero,
                                color: Colors.grey[700],
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
                        const SizedBox(height: 12), // Exact match with card
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
