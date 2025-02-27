import 'package:flutter/material.dart';

class DetailArtikelScreen extends StatelessWidget {
  final String title;
  final String content;
  final String? arsipPath;
  final String baseUrl = 'http://10.0.2.2:8000';

  const DetailArtikelScreen({
    Key? key,
    required this.title,
    required this.content,
    this.arsipPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title:
            const Text('Detail Artikel', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan gambar jika tersedia
            if (arsipPath != null)
              Container(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  '$baseUrl/storage/$arsipPath',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    content,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
