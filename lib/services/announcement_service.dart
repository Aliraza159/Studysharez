// lib/services/announcement_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String postedBy;   // admin's name
  final int createdAt;     // epoch ms

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.postedBy,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> data, String id) {
    return Announcement(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      postedBy: data['postedBy'] ?? 'Admin',
      createdAt: data['createdAt'] ?? 0,
    );
  }
}

class AnnouncementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Stream all announcements ordered newest-first ────────────────────────
  Stream<List<Announcement>> streamAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Announcement.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─── Post a new announcement (admin only) ────────────────────────────────
  Future<void> postAnnouncement({
    required String title,
    required String body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final adminName = userDoc.data()?['name'] ?? user.email ?? 'Admin';

    await _db.collection('announcements').add({
      'title': title.trim(),
      'body': body.trim(),
      'postedBy': adminName,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Delete an announcement ───────────────────────────────────────────────
  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  // ─── Read-state helpers (stored locally per user) ─────────────────────────
  // Key format: "read_announcements_<uid>"  →  comma-separated list of IDs
  static Future<Set<String>> getReadIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('read_announcements_$uid') ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  static Future<void> markAsRead(String announcementId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final key = 'read_announcements_$uid';
    final raw = prefs.getString(key) ?? '';
    final ids = raw.isEmpty ? <String>{} : raw.split(',').toSet();
    ids.add(announcementId);
    await prefs.setString(key, ids.join(','));
  }

  static Future<void> markAllAsRead(List<String> ids) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final prefs = await SharedPreferences.getInstance();
    final key = 'read_announcements_$uid';
    final raw = prefs.getString(key) ?? '';
    final existing = raw.isEmpty ? <String>{} : raw.split(',').toSet();
    existing.addAll(ids);
    await prefs.setString(key, existing.join(','));
  }
}