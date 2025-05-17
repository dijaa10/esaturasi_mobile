import 'dart:convert';
import 'package:flutter/foundation.dart';

class Schedule {
  final int id;
  final int classroomId;
  final int subjectId;
  final int teacherId;
  final int archiveId;
  final String createdAt;
  final String updatedAt;

  // Relasi dengan model lain - sesuai dengan Laravel model
  final String subjectName; // dari relasi Subject (mata pelajaran)
  final String classroomName; // dari relasi Classroom (kelas)
  final String teacherName; // dari relasi User via teacher_id (guru)

  // Schedule data yang disimpan sebagai JSON dalam kolom schedule
  final Map<String, dynamic> scheduleData; // Berisi data jadwal lengkap

  // Untuk menampilkan data satu hari tertentu
  String hari;
  String jamMulai;
  String jamSelesai;

  Schedule({
    required this.id,
    required this.classroomId,
    required this.subjectId,
    required this.teacherId,
    required this.archiveId,
    required this.createdAt,
    required this.updatedAt,
    required this.subjectName,
    required this.classroomName,
    required this.teacherName,
    required this.scheduleData,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("Raw JSON data: $json");
    }

    // Ambil subject name (mata pelajaran)
    String subjectNameValue = '';
    if (json.containsKey('subject') && json['subject'] is Map) {
      subjectNameValue = json['subject']['name']?.toString() ?? '';
    } else if (json.containsKey('name')) {
      subjectNameValue = json['name']?.toString() ?? '';
    } else {
      subjectNameValue = 'Tidak ada mata pelajaran';
    }

    // Ambil classroom name (kelas)
    String classroomNameValue = '';
    if (json.containsKey('classroom') && json['classroom'] is Map) {
      classroomNameValue = json['classroom']['name']?.toString() ?? '';
    } else if (json.containsKey('name')) {
      classroomNameValue = json['name']?.toString() ?? '';
    } else {
      classroomNameValue = 'Tidak ada kelas';
    }

    // Ambil teacher name (guru)
    String teacherNameValue = '';
    if (json.containsKey('teacher') && json['teacher'] is Map) {
      teacherNameValue = json['teacher']['name']?.toString() ?? '';
    } else if (json.containsKey('name')) {
      teacherNameValue = json['name']?.toString() ?? '';
    } else {
      teacherNameValue = 'Tidak ada guru';
    }

    // Parse data schedule
    Map<String, dynamic> scheduleData = {};
    List<Map<String, dynamic>> scheduleDays = [];
    List<String> hariList = [];

    // Default values for single day schedule
    String hariDefault = 'Tidak ada';
    String jamMulaiDefault = '';
    String jamSelesaiDefault = '';

    try {
      // Direct access to start and end times if they exist at the top level
      if (json.containsKey('start')) {
        jamMulaiDefault = json['start']?.toString() ?? '';
      }
      if (json.containsKey('end')) {
        jamSelesaiDefault = json['end']?.toString() ?? '';
      }

      // Handle the schedule field
      if (json['schedule'] != null) {
        var scheduleValue;

        // Parse if string
        if (json['schedule'] is String) {
          try {
            scheduleValue = jsonDecode(json['schedule']);
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing schedule JSON string: $e");
            }
            scheduleValue = null;
          }
        } else {
          scheduleValue = json['schedule'];
        }

        // Process schedule data based on its type
        if (scheduleValue is List && scheduleValue.isNotEmpty) {
          // List format: [{day: "Senin", end: "10:00", start: "07:00"}, {...}]
          for (var daySchedule in scheduleValue) {
            if (daySchedule is Map && daySchedule.containsKey('day')) {
              var dayData = Map<String, dynamic>.from(daySchedule);
              scheduleDays.add(dayData);
              hariList.add(daySchedule['day']?.toString() ?? '');
            }
          }

          // Save first day's times if we haven't found them yet
          if (scheduleDays.isNotEmpty) {
            hariDefault = hariList.isNotEmpty ? hariList[0] : 'Tidak ada';
            jamMulaiDefault = jamMulaiDefault.isEmpty
                ? scheduleDays[0]['start']?.toString() ?? ''
                : jamMulaiDefault;
            jamSelesaiDefault = jamSelesaiDefault.isEmpty
                ? scheduleDays[0]['end']?.toString() ?? ''
                : jamSelesaiDefault;
          }

          // Store all days in scheduleData
          for (int i = 0; i < scheduleDays.length; i++) {
            scheduleData['day${i + 1}'] = scheduleDays[i];
          }
        }
        // Single day format: {day: "Senin", end: "10:00", start: "07:00"}
        else if (scheduleValue is Map) {
          scheduleData = Map<String, dynamic>.from(scheduleValue);

          // Extract day and times
          if (scheduleData.containsKey('day')) {
            hariDefault = scheduleData['day']?.toString() ?? 'Tidak ada';
            hariList.add(hariDefault);
          }

          // Update times if they exist in the schedule map
          if (scheduleData.containsKey('start') && jamMulaiDefault.isEmpty) {
            jamMulaiDefault = scheduleData['start']?.toString() ?? '';
          }
          if (scheduleData.containsKey('end') && jamSelesaiDefault.isEmpty) {
            jamSelesaiDefault = scheduleData['end']?.toString() ?? '';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processing schedule: $e");
      }
      scheduleData = {'error': 'Processing error'};
    }

    // Debug output to verify the values
    if (kDebugMode) {
      print(
          "Parsed values - Day: $hariDefault, Start: $jamMulaiDefault, End: $jamSelesaiDefault");
    }

    return Schedule(
      id: json['id'] ?? 0,
      classroomId: json['classroom_id'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      archiveId: json['archive_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      subjectName: subjectNameValue,
      classroomName: classroomNameValue,
      teacherName: teacherNameValue,
      scheduleData: scheduleData,
      hari: hariDefault,
      jamMulai: jamMulaiDefault,
      jamSelesai: jamSelesaiDefault,
    );
  }
  // Membuat daftar jadwal terpisah untuk setiap hari
  List<Schedule> expandToMultiDay() {
    List<Schedule> scheduleList = [];

    // Kasus 1: Format array di Laravel - akan disimpan dengan key day1, day2, dsb.
    scheduleData.keys.forEach((key) {
      if (key.startsWith('day') && scheduleData[key] is Map) {
        var dayData = scheduleData[key];
        if (dayData.containsKey('day')) {
          String hari = dayData['day'];
          String jamMulai = dayData['start'] ?? '';
          String jamSelesai = dayData['end'] ?? '';

          scheduleList.add(Schedule(
            id: this.id,
            classroomId: this.classroomId,
            subjectId: this.subjectId,
            teacherId: this.teacherId,
            archiveId: this.archiveId,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
            subjectName: this.subjectName,
            classroomName: this.classroomName,
            teacherName: this.teacherName,
            scheduleData: this.scheduleData,
            hari: hari,
            jamMulai: jamMulai,
            jamSelesai: jamSelesai,
          ));
        }
      }
    });

    // Kasus 2: Format single day
    if (scheduleData.containsKey('day')) {
      return [this]; // Single day format, return jadwal asli
    }

    // Jika tidak ada jadwal yang valid ditemukan, kembalikan jadwal asli
    return scheduleList.isEmpty ? [this] : scheduleList;
  }

  // Method untuk mendapatkan schedule sebagai String untuk disimpan ke database
  String getScheduleJson() {
    // Jika ini adalah single day schedule
    if (scheduleData.containsKey('day')) {
      return jsonEncode(scheduleData);
    }

    // Jika ini adalah multiple day schedule, kita perlu format sebagai array
    List<Map<String, dynamic>> scheduleArray = [];

    // Ambil data dari scheduleData yang disimpan dengan prefix 'day'
    scheduleData.keys.forEach((key) {
      if (key.startsWith('day') && scheduleData[key] is Map) {
        scheduleArray.add(Map<String, dynamic>.from(scheduleData[key]));
      }
    });

    // Jika tidak ada data multi-hari yang ditemukan, buat dari data saat ini
    if (scheduleArray.isEmpty) {
      scheduleArray.add({'day': hari, 'start': jamMulai, 'end': jamSelesai});
    }

    return jsonEncode(scheduleArray);
  }

  // Menambahkan hari baru ke jadwal
  void addDay(String hari, String jamMulai, String jamSelesai) {
    // Cari index tertinggi dari key 'day' yang sudah ada
    int maxIndex = 0;
    scheduleData.keys.forEach((key) {
      if (key.startsWith('day')) {
        try {
          int index = int.parse(key.substring(3));
          if (index > maxIndex) maxIndex = index;
        } catch (e) {
          // Ignore parsing errors
        }
      }
    });

    // Tambahkan hari baru dengan index berikutnya
    scheduleData['day${maxIndex + 1}'] = {
      'day': hari,
      'start': jamMulai,
      'end': jamSelesai
    };
  }
}
