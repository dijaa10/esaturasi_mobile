import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:esaturasi/model/announcement.dart';
import 'announcementdetailpage.dart';

class Announcementpage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<Announcementpage> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  final String baseUrl = "https://esaturasi.my.id/";

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}api/announcement"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _announcements =
              data.map((item) => Announcement.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Gagal mengambil data pengumuman: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching pengumuman: $e");
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

  String _formatDate(String dateString) {
    try {
      if (dateString.contains('<')) {
        dateString = _extractTextFromHtml(dateString);
      }
      DateTime date = DateTime.parse(dateString);
      List<String> monthNames = [
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
      return "${date.day} ${monthNames[date.month - 1]} ${date.year}";
    } catch (e) {
      if (dateString.contains('<')) {
        return _extractTextFromHtml(dateString);
      }
      return dateString;
    }
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    String formattedDate = _formatDate(announcement.date ?? "");
    String plainContent = _extractTextFromHtml(announcement.content ?? "");
    String limitedContent = _limitToChars(plainContent, 115);
    bool isTruncated = plainContent != limitedContent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Announcementdetailpage(announcement: announcement),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative top line element
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
                          announcement.title ?? "Tanpa Judul",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
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
                              color: const Color(0xFF1976D2).withOpacity(0.2),
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
                              formattedDate,
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
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[100]!,
                          width: 0.8,
                        )),
                    child: Text(
                      limitedContent + (isTruncated ? "..." : ""),
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Announcementdetailpage(
                                announcement: announcement),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text(
                        'Baca Selengkapnya',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        backgroundColor:
                            const Color(0xFF1976D2).withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 60,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue.shade600,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 22,
                    color: Colors.white, // Warna putih
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Pengumuman Siswa',
                    style: TextStyle(
                      color: Colors.white, // Warna putih
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchAnnouncements();
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _announcements.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Tidak ada pengumuman saat ini",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Coba refresh halaman ini nanti",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade50,
                          padding: EdgeInsets.only(top: 16, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                child: Text(
                                  "Daftar Pengumuman",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.only(top: 8, bottom: 20),
                                itemCount: _announcements.length,
                                itemBuilder: (context, index) {
                                  return _buildAnnouncementCard(
                                      _announcements[index]);
                                },
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

String _limitToChars(String text, int charLimit) {
  // If the text has fewer characters than the limit, return the original text
  if (text.length <= charLimit) {
    return text;
  }

  // Otherwise, return only the first 'charLimit' characters
  return text.substring(0, charLimit);
}
