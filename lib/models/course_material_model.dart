// lib/models/course_material_model.dart

class CourseMaterial {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String fileType; // 'pdf', 'ppt', 'doc', 'other'
  final String fileUrl;
  final int fileSize;
  final DateTime uploadedAt;
  final String uploadedBy;     // teacher's uid
  final String teacherName;
  final String courseId;
  final String courseName;
  final String courseCode;

  CourseMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.teacherName,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(uploadedAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}';
  }

  factory CourseMaterial.fromMap(Map<String, dynamic> map, String id) {
    return CourseMaterial(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? 'other',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] ?? 0),
      uploadedBy: map['uploadedBy'] ?? '',
      teacherName: map['teacherName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      courseCode: map['courseCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
      'uploadedBy': uploadedBy,
      'teacherName': teacherName,
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
    };
  }
}