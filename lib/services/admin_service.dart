// lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/course_model.dart';
import '../models/course_material_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Check if current user is admin ──────────────────────────────────────
  Future<bool> isAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  // ─── Dashboard Stats ──────────────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    final users = await _db.collection('users').get();
    final courses = await _db.collection('courses').get();
    final materials = await _db.collection('materials').get();

    int studentCount = 0;
    int teacherCount = 0;
    int adminCount = 0;
    int totalFiles = 0;

    for (final doc in users.docs) {
      final role = doc.data()['role'] ?? 'student';
      if (role == 'student') studentCount++;
      if (role == 'teacher') teacherCount++;
      if (role == 'admin') adminCount++;
    }

    for (final courseDoc in materials.docs) {
      final filesSnap = await _db
          .collection('materials')
          .doc(courseDoc.id)
          .collection('files')
          .get();
      totalFiles += filesSnap.docs.length;
    }

    return {
      'totalUsers': users.docs.length,
      'students': studentCount,
      'teachers': teacherCount,
      'admins': adminCount,
      'courses': courses.docs.length,
      'materials': totalFiles,
    };
  }

  // ─── Users ────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snap) => snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ─── Create New User (secondary app trick keeps admin logged in) ──────────
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // Use a secondary Firebase app so the admin's session is NOT disturbed
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('secondary');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final newUid = credential.user!.uid;

    // Save user profile to Firestore
    await _db.collection('users').doc(newUid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'isBlocked': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Sign out from secondary app only — admin stays logged in
    await secondaryAuth.signOut();
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection('users').doc(uid).update({'role': newRole});
  }

  Future<void> toggleUserBlock(String uid, bool isBlocked) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'isBlocked': isBlocked});
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ─── Courses ──────────────────────────────────────────────────────────────
  Stream<List<Course>> streamAllCourses() {
    return _db.collection('courses').snapshots().map((snap) =>
        snap.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> createCourse({
    required String name,
    required String code,
    required String semester,
    required String teacherId,
  }) async {
    await _db.collection('courses').add({
      'name': name,
      'code': code,
      'semester': semester,
      'teacherId': teacherId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateCourse({
    required String courseId,
    required String name,
    required String code,
    required String semester,
    required String teacherId,
  }) async {
    await _db.collection('courses').doc(courseId).update({
      'name': name,
      'code': code,
      'semester': semester,
      'teacherId': teacherId,
    });
  }

  Future<void> deleteCourse(String courseId) async {
    // Delete all files subcollection first
    final filesSnap = await _db
        .collection('materials')
        .doc(courseId)
        .collection('files')
        .get();
    for (final doc in filesSnap.docs) {
      await doc.reference.delete();
    }
    // Delete materials parent doc
    await _db.collection('materials').doc(courseId).delete();
    // Delete course doc
    await _db.collection('courses').doc(courseId).delete();
  }

  // ─── Materials (Admin can delete any) ────────────────────────────────────
  Stream<List<CourseMaterial>> streamAllMaterials() {
    return _db
        .collection('materials')
        .snapshots()
        .asyncMap((courseDocs) async {
      final List<CourseMaterial> all = [];
      for (final courseDoc in courseDocs.docs) {
        try {
          final filesSnap = await _db
              .collection('materials')
              .doc(courseDoc.id)
              .collection('files')
              .orderBy('uploadedAt', descending: true)
              .get();
          all.addAll(filesSnap.docs
              .map((doc) => CourseMaterial.fromMap(doc.data(), doc.id)));
        } catch (_) {
          continue;
        }
      }
      all.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return all;
    });
  }

  Future<void> deleteMaterial(String courseId, String materialId) async {
    await _db
        .collection('materials')
        .doc(courseId)
        .collection('files')
        .doc(materialId)
        .delete();
  }

  // ─── Get teachers list for course assignment ──────────────────────────────
  Future<List<Map<String, dynamic>>> getTeachers() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();
    return snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }
}