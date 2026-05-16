// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a single material-upload notification
class MaterialNotification {
  final String id;             // unique id (file doc id)
  final String title;          // material title
  final String courseName;
  final String courseCode;
  final String teacherName;
  final String fileType;
  final int uploadedAt;        // epoch ms

  MaterialNotification({
    required this.id,
    required this.title,
    required this.courseName,
    required this.courseCode,
    required this.teacherName,
    required this.fileType,
    required this.uploadedAt,
  });

  factory MaterialNotification.fromMap(Map<String, dynamic> m, String id) {
    return MaterialNotification(
      id: id,
      title: m['title'] ?? 'Untitled',
      courseName: m['courseName'] ?? '',
      courseCode: m['courseCode'] ?? '',
      teacherName: m['teacherName'] ?? 'Teacher',
      fileType: m['fileType'] ?? 'other',
      uploadedAt: m['uploadedAt'] ?? 0,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _readKey = 'read_material_notifications';
  static const _lastSeenKey = 'last_seen_notification_ts';

  /// Stream all material uploads across courses (newest first).
  /// Same iteration pattern as MaterialService.streamAllMaterials() so it
  /// works on Spark plan without a collectionGroup index.
  Stream<List<MaterialNotification>> streamMaterialNotifications() {
    return _db.collection('materials').snapshots().asyncMap((courseDocs) async {
      final List<MaterialNotification> all = [];

      for (final courseDoc in courseDocs.docs) {
        try {
          final filesSnap = await _db
              .collection('materials')
              .doc(courseDoc.id)
              .collection('files')
              .orderBy('uploadedAt', descending: true)
              .limit(20) // recent only per course
              .get();

          for (final f in filesSnap.docs) {
            all.add(MaterialNotification.fromMap(f.data(), f.id));
          }
        } catch (_) {
          continue;
        }
      }

      all.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return all.take(30).toList(); // latest 30 globally
    });
  }

  // ─── Read-state persistence (SharedPreferences) ───────────────────────────
  static Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readKey) ?? []).toSet();
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_readKey) ?? []).toSet()..add(id);
    await prefs.setStringList(_readKey, ids.toList());
  }

  static Future<void> markAllAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getStringList(_readKey) ?? []).toSet()..addAll(ids);
    await prefs.setStringList(_readKey, existing.toList());
    await prefs.setInt(_lastSeenKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int> getLastSeenTs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSeenKey) ?? 0;
  }
}