import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/jadwal.dart';
import 'dart:convert'; // Import untuk decode JSON

class MapelPage extends StatefulWidget {
  @override
  _MapelPageState createState() => _MapelPageState();
}

class _MapelPageState extends State<MapelPage> {
  // Data mata pelajaran yang diampuh
  List<Jadwal> mataPelajaran = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final String baseUrl = "http://10.0.2.2:8000/";

  @override
  void initState() {
    super.initState();
    _fetchJadwal();
  }

  Future<void> _fetchJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Ambil kelas_id dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String kelasId = prefs.getString('kelas_id') ??
          ''; // Ambil kelas_id yang sudah disimpan

      if (kelasId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ID Kelas tidak ditemukan";
        });
        return;
      }

      final response =
          await http.get(Uri.parse("${baseUrl}api/jadwal/kelas/$kelasId"));

      // Log the raw response for debugging
      print("Raw response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Log parsed data length
        print("Parsed data length: ${data.length}");
        if (data.isNotEmpty) {
          print("First item sample: ${data[0]}");
        }

        setState(() {
          mataPelajaran = data.map((item) => Jadwal.fromJson(item)).toList();
          _isLoading = false;

          // Debug log of parsed objects
          print("Converted to ${mataPelajaran.length} Jadwal objects");
          if (mataPelajaran.isNotEmpty) {
            print(
                "Sample jadwal: Mata Pelajaran=${mataPelajaran[0].mataPelajaran}, Hari=${mataPelajaran[0].hari}");
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal mengambil data jadwal: ${response.statusCode}";
        });
        print(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching jadwal: $e";
      });
      print(_errorMessage);
    }
  }

  // Default to current day of week instead of 'Semua'
  String filterHari = _getCurrentDayInIndonesian();
  final List<String> hariOptions = [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat'
  ];

  // Helper method to get current day name in Indonesian
  static String _getCurrentDayInIndonesian() {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    // Get current day (1 = Monday, 7 = Sunday)
    final dayOfWeek = DateTime.now().weekday;
    // If weekend, default to 'Semua' instead
    if (dayOfWeek > 5) return 'Semua';
    return days[dayOfWeek - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Debug filtering process
    print("Current filter: $filterHari");
    print("Total jadwal before filtering: ${mataPelajaran.length}");

    // Filter mata pelajaran berdasarkan hari, ignoring case
    List<Jadwal> filteredMapel = filterHari == 'Semua'
        ? mataPelajaran
        : mataPelajaran
            .where(
                (mapel) => mapel.hari.toLowerCase() == filterHari.toLowerCase())
            .toList();

    print("Filtered jadwal count: ${filteredMapel.length}");

    // Debug: Print all hari values to check for inconsistencies
    if (mataPelajaran.isNotEmpty) {
      print(
          "All hari values in data: ${mataPelajaran.map((m) => m.hari).toSet().toList()}");
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar dengan judul dan filter
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Color(0xFF1976D2),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Mata Pelajaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF64B5F6)
                    ], // Gradasi biru
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -10,
                      child: Icon(
                        Icons.school,
                        size: 180,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 16),
                color: Color(0xFF1976D2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: hariOptions.map((hari) {
                      bool isSelected = filterHari == hari;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            hari,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade200,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Color(0xFF64B5F6),
                          backgroundColor: Color(0xFF1976D2),
                          onSelected: (selected) {
                            setState(() {
                              filterHari = hari;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Content area
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1976D2),
                    ),
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.red.shade300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchJadwal,
                              child: Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0xFF1976D2), // Corrected from primary
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : mataPelajaran.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada jadwal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredMapel.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada jadwal untuk hari ${filterHari.toLowerCase()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          filterHari = 'Semua';
                                        });
                                      },
                                      child: Text('Lihat Semua Jadwal'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(
                                            0xFF1976D2), // Corrected from primary
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final mapel = filteredMapel[index];
                                    return AnimatedCard(
                                      mapel: mapel,
                                      index: index,
                                    );
                                  },
                                  childCount: filteredMapel.length,
                                ),
                              ),
                            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1976D2),
        child: Icon(Icons.refresh),
        onPressed: () {
          _fetchJadwal();
        },
      ),
    );
  }
}

class AnimatedCard extends StatelessWidget {
  final Jadwal mapel;
  final int index;

  const AnimatedCard({
    Key? key,
    required this.mapel,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int hashCode = mapel.mataPelajaran.hashCode;
    final color = Colors.primaries[hashCode % Colors.primaries.length];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: 1.0,
      curve: Curves.easeInOut,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetailBottomSheet(context, mapel, color),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon buku
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.book, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                // Informasi Mata Pelajaran
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mapel.mataPelajaran}', // Nama mata pelajaran
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kelas: ${mapel.kelas}', // Nama kelas
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${mapel.guru}", // Nama guru
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hari & Jam
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mapel.hari, // Hari
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${mapel.jamMulai} - ${mapel.jamSelesai}", // Jam mulai - Jam selesai
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context, Jadwal mapel, Color color) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.book,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${mapel.mataPelajaran}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "${mapel.guru}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Lihat Tugas'),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan aksi edit
                },
              ),
              ListTile(
                leading: Icon(Icons.assignment, color: Colors.green),
                title: Text('Lihat Materi'),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan aksi lihat materi
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
