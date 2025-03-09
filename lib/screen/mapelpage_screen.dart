import 'package:flutter/material.dart';
import 'dart:math';

class MapelPage extends StatefulWidget {
  @override
  _MapelPageState createState() => _MapelPageState();
}

class _MapelPageState extends State<MapelPage> {
  // Data contoh mata pelajaran yang diampuh
  final List<Map<String, dynamic>> mataPelajaran = [
    {
      'nama': 'Matematika',
      'kelas': 'X IPA',
      'waktu': '08:00 - 09:30',
      'hari': 'Senin',
      'icon': Icons.calculate,
      'color': Colors.blue,
    },
    {
      'nama': 'Fisika',
      'kelas': 'XII IPA',
      'waktu': '13:00 - 14:30',
      'hari': 'Rabu',
      'icon': Icons.flash_on,
      'color': Colors.purple,
    },
    {
      'nama': 'Kimia',
      'kelas': 'X IPA',
      'waktu': '09:30 - 11:00',
      'hari': 'Kamis',
      'icon': Icons.science,
      'color': Colors.green,
    },
    {
      'nama': 'Biologi',
      'kelas': 'XI IPA',
      'waktu': '07:30 - 09:00',
      'hari': 'Jumat',
      'icon': Icons.biotech,
      'color': Colors.orange,
    },
    {
      'nama': 'Bahasa Inggris',
      'kelas': 'XII IPS',
      'waktu': '08:00 - 09:30',
      'hari': 'Selasa',
      'icon': Icons.language,
      'color': Colors.indigo,
    },
  ];

  String filterHari = 'Semua';
  final List<String> hariOptions = [
    'Semua',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat'
  ];

  @override
  Widget build(BuildContext context) {
    // Filter mata pelajaran berdasarkan hari
    List<Map<String, dynamic>> filteredMapel = filterHari == 'Semua'
        ? mataPelajaran
        : mataPelajaran.where((mapel) => mapel['hari'] == filterHari).toList();

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

          // Jumlah mata pelajaran yang ditampilkan
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${filteredMapel.length} mata pelajaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.sort,
                      color: Color(0xFF1976D2),
                    ),
                    onPressed: () {
                      // Fungsi untuk mengurutkan mata pelajaran
                    },
                  ),
                ],
              ),
            ),
          ),

          // Daftar mata pelajaran
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: filteredMapel.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 50),
                          Icon(
                            Icons.weekend,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tidak ada mata pelajaran untuk hari $filterHari',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
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
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Map<String, dynamic> mapel;
  final int index;

  AnimatedCard({required this.mapel, required this.index});

  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Aksi ketika kartu diklik
            },
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ikon mata pelajaran dengan latar belakang warna
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.mapel['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.mapel['icon'],
                      size: 30,
                      color: widget.mapel['color'],
                    ),
                  ),
                  SizedBox(width: 16),
                  // Informasi mata pelajaran
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mapel['nama'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelas ${widget.mapel['kelas']}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.mapel['hari'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.mapel['waktu'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tombol menu
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) =>
                            MapelActionSheet(mapel: widget.mapel),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapelActionSheet extends StatelessWidget {
  final Map<String, dynamic> mapel;

  MapelActionSheet({required this.mapel});

  @override
  Widget build(BuildContext context) {
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
                  color: mapel['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  mapel['icon'],
                  color: mapel['color'],
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mapel['nama'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Kelas ${mapel['kelas']}',
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
            title: Text('Edit Mata Pelajaran'),
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
          ListTile(
            leading: Icon(Icons.people, color: Colors.orange),
            title: Text('Daftar Siswa'),
            onTap: () {
              Navigator.pop(context);
              // Tambahkan aksi lihat daftar siswa
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Hapus'),
            onTap: () {
              Navigator.pop(context);
              // Tambahkan aksi hapus
            },
          ),
        ],
      ),
    );
  }
}
