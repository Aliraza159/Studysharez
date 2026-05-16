// lib/services/material_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/course_material_model.dart';
import '../models/course_model.dart';

class MaterialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Cloudinary Config ────────────────────────────────────────────────────
  // Replace with your actual values from cloudinary.com dashboard
  static const String _cloudName = 'dxasvehbu';    // e.g. 'dxyz1234'
  static const String _uploadPreset = 'uni_app_uploads'; // preset you created

  // ─── Upload file to Cloudinary + save metadata to Firestore ──────────────
  Future<void> uploadMaterial({
    required Course course,
    required String title,
    required String description,
    required File file,
    required String fileName,
    required String fileType,
    required int fileSize,
    required Function(double) onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Fetch teacher name from Firestore
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final teacherName = userDoc.data()?['name'] ?? user.email ?? 'Teacher';

    // ── Step 1: Upload file to Cloudinary ────────────────────────────────
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload',
    );

    onProgress(0.05);

    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['resource_type'] = 'raw'
      ..fields['folder'] = 'materials/${course.id}'
      ..fields['public_id'] = '${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: fileName,
      ));

    onProgress(0.4);

    final streamedResponse = await request.send();
    onProgress(0.8);

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final downloadUrl = responseData['secure_url'] as String;
    final publicId = responseData['public_id'] as String;

    onProgress(0.9);

    // ── Step 2: Save metadata to Firestore ───────────────────────────────
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // IMPORTANT: Create the parent course document so streamAllMaterials()
    // can find this course when looping through the materials collection.
    // SetOptions(merge: true) ensures we never overwrite existing data.
    await _db.collection('materials').doc(course.id).set({
      'courseId': course.id,
      'courseName': course.name,
      'courseCode': course.code,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    // Save the actual file metadata in the files subcollection
    await _db
        .collection('materials')
        .doc(course.id)
        .collection('files')
        .add({
      'title': title,
      'description': description,
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': downloadUrl,
      'publicId': publicId,
      'fileSize': fileSize,
      'uploadedAt': timestamp,
      'uploadedBy': user.uid,
      'teacherName': teacherName,
      'courseId': course.id,
      'courseName': course.name,
      'courseCode': course.code,
    });

    onProgress(1.0);
  }

  // ─── Delete material ──────────────────────────────────────────────────────
  Future<void> deleteMaterial({
    required String courseId,
    required String materialId,
    required String fileUrl,
    String? publicId,
  }) async {
    await _db
        .collection('materials')
        .doc(courseId)
        .collection('files')
        .doc(materialId)
        .delete();
  }

  // ─── Stream materials for one course (teacher detail view) ───────────────
  Stream<List<CourseMaterial>> streamMaterialsForCourse(String courseId) {
    return _db
        .collection('materials')
        .doc(courseId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => CourseMaterial.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─── Stream ALL materials across all courses (student screen) ────────────
  // Reads materials collection docs first (one per course), then fetches
  // each course's files subcollection individually.
  // No collectionGroup index required — works on free Spark plan.
  Stream<List<CourseMaterial>> streamAllMaterials() {
    return _db
        .collection('materials')
        .snapshots()
        .asyncMap((courseDocs) async {
      final List<CourseMaterial> allMaterials = [];

      for (final courseDoc in courseDocs.docs) {
        try {
          final filesSnap = await _db
              .collection('materials')
              .doc(courseDoc.id)
              .collection('files')
              .orderBy('uploadedAt', descending: true)
              .get();

          final materials = filesSnap.docs
              .map((doc) => CourseMaterial.fromMap(doc.data(), doc.id))
              .toList();

          allMaterials.addAll(materials);
        } catch (e) {
          // Skip this course if files can't be fetched, continue with rest
          continue;
        }
      }

      // Sort all merged materials by date descending
      allMaterials.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return allMaterials;
    });
  }

  // ─── Stream teacher's own courses ────────────────────────────────────────
  Stream<List<Course>> streamTeacherCourses() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('courses')
        .where('teacherId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─── Stream material counts per course ───────────────────────────────────
  Stream<Map<String, int>> streamCourseMaterialCounts(String courseId) {
    return streamMaterialsForCourse(courseId).map((materials) => {
      'total': materials.length,
      'pdf': materials.where((m) => m.fileType == 'pdf').length,
      'ppt': materials.where((m) => m.fileType == 'ppt').length,
      'doc': materials.where((m) => m.fileType == 'doc').length,
    });
  }
}