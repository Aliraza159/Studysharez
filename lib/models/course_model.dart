// lib/models/course_model.dart

class Course {
  final String id;
  final String name;
  final String code;
  final String semester;
  final String teacherId;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.semester,
    required this.teacherId,
  });

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      semester: map['semester'] ?? '',
      teacherId: map['teacherId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'semester': semester,
      'teacherId': teacherId,
    };
  }
}