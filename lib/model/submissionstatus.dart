class SubmissionModel {
  final int id;
  final int taskId;
  final int studentId;
  final String filePath;
  final int? assignment;
  final String status;
  final String createdAt;
  final String? taskTitle;

  SubmissionModel({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.filePath,
    this.assignment,
    required this.status,
    required this.createdAt,
    this.taskTitle,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'],
      taskId: json['task_id'],
      studentId: json['student_id'],
      filePath: json['file_path'],
      assignment: json['assignment'],
      status: json['status'],
      createdAt: json['created_at'],
      taskTitle: json['task_title'],
    );
  }

  // Getter untuk status yang lebih user-friendly
  String get statusText {
    switch (status) {
      case 'submitted':
        return 'Sudah Dikumpulkan';
      case 'graded':
        return 'Sudah Dinilai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  // Getter untuk warna status
  String get statusColor {
    switch (status) {
      case 'submitted':
        return '#FFC107'; // Warna kuning untuk status menunggu
      case 'graded':
        return '#4CAF50'; // Warna hijau untuk status sudah dinilai
      case 'rejected':
        return '#F44336'; // Warna merah untuk status ditolak
      default:
        return '#9E9E9E'; // Warna abu-abu untuk status lainnya
    }
  }
}
