import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

Future<void> downloadAndShareImage(
    String imageUrl, BuildContext context) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Langsung bagikan file menggunakan share_plus
      await Share.shareXFiles([XFile(file.path)], text: 'Lihat gambar ini!');
    } else {
      throw Exception('Gagal mengunduh gambar');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  }
}

void showAttachmentDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () async {
                    await downloadAndShareImage(imageUrl, context);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
