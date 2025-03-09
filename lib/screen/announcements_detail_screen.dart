import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'announcements_detail_screen.dart';

class PengumumanDetailPage extends StatefulWidget {
  final Pengumuman announcement;

  const PengumumanDetailPage({Key? key, required this.announcement})
      : super(key: key);

  @override
  State<PengumumanDetailPage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<PengumumanDetailPage> {
  bool _isLoading = false;
  late Pengumuman _detailedAnnouncement;
  final String baseUrl = "http://127.0.0.1:8000/";

  @override
  void initState() {
    super.initState();
    _detailedAnnouncement = widget.announcement;
    // Fetch detailed announcement if needed
    _fetchDetailedAnnouncement();
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
          _detailedAnnouncement = Pengumuman.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Gagal mengambil detail pengumuman: ${response.statusCode}")),
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

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _shareAnnouncement() async {
    final String content =
        "Pengumuman: ${_detailedAnnouncement.title}\n\n${_detailedAnnouncement.plainContent}\n\nTanggal: ${_formatDate(_detailedAnnouncement.date)}";

    await Share.share(content, subject: _detailedAnnouncement.title);
  }

  Future<void> _downloadAttachment() async {
    if (_detailedAnnouncement.attachmentUrl == null ||
        _detailedAnnouncement.attachmentUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada lampiran untuk diunduh")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse(_detailedAnnouncement.attachmentUrl!));

      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName =
            _detailedAnnouncement.attachmentUrl!.split('/').last;
        final String filePath = '${tempDir.path}/$fileName';

        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil mengunduh lampiran ke: $filePath")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Gagal mengunduh lampiran: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error mengunduh lampiran: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _formatDate(_detailedAnnouncement.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAnnouncement,
            tooltip: 'Bagikan',
          ),
          if (_detailedAnnouncement.attachmentUrl != null &&
              _detailedAnnouncement.attachmentUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadAttachment,
              tooltip: 'Unduh Lampiran',
            ),
        ],
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
                          _detailedAnnouncement.title,
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
                                formattedDate,
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

                  // Author info if available
                  if (_detailedAnnouncement.author != null &&
                      _detailedAnnouncement.author!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE0E0E0),
                            child: Icon(Icons.person, color: Color(0xFF757575)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diposting oleh',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              Text(
                                _detailedAnnouncement.author!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _detailedAnnouncement.htmlContent != null &&
                            _detailedAnnouncement.htmlContent!.isNotEmpty
                        ? Html(
                            data: _detailedAnnouncement.htmlContent!,
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                lineHeight: LineHeight(1.6),
                              ),
                              "a": Style(
                                color: const Color(0xFF1976D2),
                                textDecoration: TextDecoration.none,
                              ),
                            },
                          )
                        : Text(
                            _detailedAnnouncement.plainContent,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                  ),

                  // Attachment section if available
                  if (_detailedAnnouncement.attachmentUrl != null &&
                      _detailedAnnouncement.attachmentUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Lampiran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _downloadAttachment,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    color: Color(0xFF1976D2),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _detailedAnnouncement.attachmentUrl!
                                          .split('/')
                                          .last,
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.download,
                                    color: Color(0xFF1976D2),
                                  ),
                                ],
                              ),
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

// Make sure you have this model class defined somewhere in your code
class Pengumuman {
  final int id;
  final String title;
  final String plainContent;
  final String? htmlContent;
  final String date;
  final String? author;
  final String? attachmentUrl;

  Pengumuman({
    required this.id,
    required this.title,
    required this.plainContent,
    this.htmlContent,
    required this.date,
    this.author,
    this.attachmentUrl,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'],
      title: json['title'],
      plainContent: json['content'] ?? json['plain_content'] ?? '',
      htmlContent: json['html_content'],
      date: json['date'] ?? json['created_at'] ?? DateTime.now().toString(),
      author: json['author'] ?? json['posted_by'],
      attachmentUrl: json['attachment_url'] ?? json['lampiran'],
    );
  }
}
