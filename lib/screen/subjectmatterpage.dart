import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/schedule1.dart';
import '../model/slug.dart';
import 'detailsubjectmatterpage.dart';
import 'package:google_fonts/google_fonts.dart';

class MateriPage extends StatefulWidget {
  final Schedule mapel;

  const MateriPage({Key? key, required this.mapel}) : super(key: key);

  @override
  _MateriPageState createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage>
    with SingleTickerProviderStateMixin {
  List<Slug> slugs = [];
  List<Slug> filteredSlugs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final String baseUrl = "http://10.0.2.2:8000/";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Updated elegant color scheme with blue gradient for AppBar
  final Color primaryColor = Color(0xFF1976D2); // Primary blue
  final Color secondaryColor = Color(0xFF64B5F6); // Lighter blue
  final Color accentColor = Color(0xFF1976D2); // Keep teal for other elements
  final Color lightAccentColor = Color(0xFFEDF2F4); // Light gray/white
  final Color backgroundColor = Color(0xFFFAFAFA); // Near white
  final Color textColor = Color(0xFF2D3142); // Dark blue-gray
  final Color errorColor = Color(0xFFB23A48); // Elegant red

  @override
  void initState() {
    super.initState();

    // Initialize search controller
    _searchController.addListener(_onSearchChanged);

    // Animation setup with safer implementation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Small delay before starting animation to ensure context is ready
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    _fetchSlugs();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterSlugs(_searchController.text);
  }

  void _filterSlugs(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSlugs = List.from(slugs);
      });
    } else {
      setState(() {
        filteredSlugs = slugs
            .where((slug) =>
                slug.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        filteredSlugs = List.from(slugs);
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  Future<void> _fetchSlugs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final int jadwalId = widget.mapel.id;

      final response = await http.get(
        Uri.parse("${baseUrl}api/slugs/schedule/$jadwalId"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          slugs = data.map((item) => Slug.fromJson(item)).toList();
          filteredSlugs = List.from(slugs);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal mengambil data bab: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching slugs: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Cari judul bab...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      );
    } else {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor, // Darker blue - Color(0xFF1976D2)
                secondaryColor, // Lighter blue - Color(0xFF64B5F6)
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        title: Text(
          widget.mapel.subjectName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
            tooltip: 'Cari Materi',
          ),
        ],
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading materi...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    } else if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    } else if (filteredSlugs.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return _buildNoSearchResultsView();
      } else {
        return _buildEmptyView();
      }
    } else {
      return _buildContentList();
    }
  }

  Widget _buildNoSearchResultsView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightAccentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: accentColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Tidak ada hasil',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tidak ada bab dengan judul "${_searchController.text}"',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
              },
              child: Text(
                'Reset Pencarian',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: errorColor,
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _fetchSlugs,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Coba Lagi'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightAccentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: 60,
                color: accentColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Tidak ada materi tersedia',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Materi untuk ${widget.mapel.subjectName} belum tersedia saat ini.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return Container(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchController.text.isEmpty
                      ? 'Materi Pembelajaran'
                      : 'Hasil Pencarian',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  _searchController.text.isEmpty
                      ? '${filteredSlugs.length} bab tersedia'
                      : '${filteredSlugs.length} bab ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 80),
              itemCount: filteredSlugs.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Fixed animation to ensure values stay within [0, 1] range
                    final double start = (index * 0.1).clamp(0.0, 0.9);
                    final double end = 1.0;
                    double normalizedTime = 0.0;

                    if (_animationController.value < start) {
                      normalizedTime = 0.0;
                    } else if (_animationController.value >= end) {
                      normalizedTime = 1.0;
                    } else {
                      normalizedTime =
                          (_animationController.value - start) / (end - start);
                    }

                    final animValue = Curves.easeOut.transform(normalizedTime);

                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - animValue)),
                      child: Opacity(
                        opacity: animValue,
                        child: child,
                      ),
                    );
                  },
                  child: _buildBabCard(filteredSlugs[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabCard(Slug slug, int index) {
    // Generate a consistent color based on the slug title
    final int hashCode = slug.title.hashCode;
    final List<List<Color>> colorPairs = [
      [Color(0xFF5D8CAE), Color(0xFF87BFFF)], // Blue shades
      [Color(0xFF048A81), Color(0xFF06D6A0)], // Teal shades
      [Color(0xFF7678ED), Color(0xFFA5A8FF)], // Purple shades
      [Color(0xFFF8961E), Color(0xFFF9C74F)], // Orange shades
      [Color(0xFF9B5DE5), Color(0xFFC77DFF)], // Purple shades
    ];

    final colorPair = colorPairs[hashCode % colorPairs.length];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBabDetailBottomSheet(slug, colorPair[0]),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Numbered container with gradient
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colorPair,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorPair[0].withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${_searchController.text.isEmpty ? index + 1 : slugs.indexOf(slug) + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAB ${_searchController.text.isEmpty ? index + 1 : slugs.indexOf(slug) + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        slug.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lightAccentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _fetchSlugs,
      backgroundColor: accentColor,
      elevation: 2,
      icon: Icon(Icons.refresh_rounded),
      label: Text(
        'Refresh',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showBabDetailBottomSheet(Slug slug, Color themeColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Title and Icon
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slug.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Materi Pembelajaran',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Description
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightAccentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Materi ini mencakup konsep-konsep penting dalam pembelajaran. Anda dapat melihat atau mengunduh untuk akses offline.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.library_books_rounded),
                      label: Text('Lihat Materi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailMateriPage(slug: slug),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.download_rounded),
                      label: Text('Unduh Materi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Implement download functionality
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mengunduh materi...'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
