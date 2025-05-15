import 'dart:convert';
import 'package:flutter/foundation.dart';

class Jadwal {
  final int id;
  final String mataPelajaran;
  final String kelas;
  final String guru;
  final int idMapel;

  // Data multi-hari dalam format Map
  final Map<String, dynamic> hariData; // Menyimpan semua data hari
  final Map<String, String> jamMulaiData; // Menyimpan jam mulai per hari
  final Map<String, String> jamSelesaiData; // Menyimpan jam selesai per hari

  // Properti untuk tampilan saat ini (untuk satu hari tertentu)
  String hari;
  String jamMulai;
  String jamSelesai;

  Jadwal({
    required this.id,
    required this.mataPelajaran,
    required this.kelas,
    required this.guru,
    required this.idMapel,
    required this.hariData,
    required this.jamMulaiData,
    required this.jamSelesaiData,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("Raw JSON data: $json");
    }

    // Ambil nama mapel
    String mataPelajaranValue = '';
    if (json.containsKey('mata_pelajaran') && json['mata_pelajaran'] is Map) {
      mataPelajaranValue =
          json['mata_pelajaran']['nama_mapel']?.toString() ?? '';
    } else if (json.containsKey('nama_mapel')) {
      mataPelajaranValue = json['nama_mapel']?.toString() ?? '';
    } else {
      mataPelajaranValue = 'Tidak ada mapel';
    }

    // Ambil nama kelas
    String kelasValue = '';
    if (json.containsKey('kelas') && json['kelas'] is Map) {
      kelasValue = json['kelas']['nama_kelas']?.toString() ?? '';
    } else if (json.containsKey('nama_kelas')) {
      kelasValue = json['nama_kelas']?.toString() ?? '';
    } else {
      kelasValue = 'Tidak ada kelas';
    }

    // Ambil nama guru
    String guruValue = '';
    if (json.containsKey('guru') && json['guru'] is Map) {
      guruValue = json['guru']['nama']?.toString() ?? '';
    } else if (json.containsKey('nama_guru')) {
      guruValue = json['nama_guru']?.toString() ?? '';
    } else {
      guruValue = 'Tidak ada guru';
    }

    // Parse data hari
    List<String> hariList = [];
    Map<String, dynamic> hariData = {};

    try {
      if (json['hari'] is String) {
        try {
          // Coba parse sebagai array JSON
          var decodedHari = jsonDecode(json['hari']);
          if (decodedHari is List) {
            hariList = List<String>.from(decodedHari.map((e) => e.toString()));

            // Membuat Map untuk data hari
            for (var hari in hariList) {
              hariData[hari] = true;
            }
          } else if (decodedHari is Map) {
            // Jika datanya dalam format Map
            hariData = Map<String, dynamic>.from(decodedHari);
            hariList = hariData.keys.toList();
          }
        } catch (e) {
          // Jika bukan JSON valid, anggap sebagai string hari tunggal
          hariList = [json['hari']];
          hariData[json['hari']] = true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing hari: $e");
      }
      hariList = ['Format tidak valid'];
      hariData['Format tidak valid'] = true;
    }

    // Parse data jam mulai
    Map<String, String> jamMulaiData = {};
    try {
      if (json['jam_mulai'] is String) {
        try {
          var decodedJamMulai = jsonDecode(json['jam_mulai']);
          if (decodedJamMulai is Map) {
            jamMulaiData = Map<String, String>.from(decodedJamMulai
                .map((key, value) => MapEntry(key, value.toString())));
          }
        } catch (e) {
          // Jika bukan JSON valid, gunakan nilai mentah untuk semua hari
          for (var hari in hariList) {
            jamMulaiData[hari] = json['jam_mulai'] ?? '';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing jam mulai: $e");
      }
    }

    // Parse data jam selesai
    Map<String, String> jamSelesaiData = {};
    try {
      if (json['jam_selesai'] is String) {
        try {
          var decodedJamSelesai = jsonDecode(json['jam_selesai']);
          if (decodedJamSelesai is Map) {
            jamSelesaiData = Map<String, String>.from(decodedJamSelesai
                .map((key, value) => MapEntry(key, value.toString())));
          }
        } catch (e) {
          // Jika bukan JSON valid, gunakan nilai mentah untuk semua hari
          for (var hari in hariList) {
            jamSelesaiData[hari] = json['jam_selesai'] ?? '';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing jam selesai: $e");
      }
    }

    // Default untuk tampilan awal - gunakan hari pertama jika ada
    String hariDefault = hariList.isNotEmpty ? hariList[0] : 'Tidak ada';
    String jamMulaiDefault = jamMulaiData[hariDefault] ?? '';
    String jamSelesaiDefault = jamSelesaiData[hariDefault] ?? '';

    return Jadwal(
      id: json['id'] ?? 0,
      mataPelajaran: mataPelajaranValue,
      kelas: kelasValue,
      guru: guruValue,
      idMapel: json['mata_pelajaran_id'] ?? 0,
      hariData: hariData,
      jamMulaiData: jamMulaiData,
      jamSelesaiData: jamSelesaiData,
      hari: hariDefault,
      jamMulai: jamMulaiDefault,
      jamSelesai: jamSelesaiDefault,
    );
  }

  // Membuat daftar jadwal terpisah untuk setiap hari
  List<Jadwal> expandToMultiDay() {
    List<Jadwal> jadwalList = [];

    // Pastikan hariData tidak kosong
    if (hariData.isEmpty) {
      return [this]; // Kembalikan jadwal asli jika tidak ada data multi-hari
    }

    // Buat satu objek Jadwal untuk setiap hari
    for (var hari in hariData.keys) {
      jadwalList.add(Jadwal(
        id: this.id,
        mataPelajaran: this.mataPelajaran,
        kelas: this.kelas,
        guru: this.guru,
        idMapel: this.idMapel,
        hariData: this.hariData,
        jamMulaiData: this.jamMulaiData,
        jamSelesaiData: this.jamSelesaiData,
        hari: hari,
        jamMulai: jamMulaiData[hari] ?? '',
        jamSelesai: jamSelesaiData[hari] ?? '',
      ));
    }

    return jadwalList;
  }
}
