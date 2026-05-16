// lib/screens/teacher/teacher_profile_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'my_info_screen.dart';
import 'notifications_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import '../auth/login_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  // ── Cloudinary config (same as MaterialService) ──────────────────────────
  static const String _cloudName = 'dxasvehbu';
  static const String _uploadPreset = 'uni_app_uploads';

  String? _photoURL;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  // ── Load saved photo URL from Firestore ──────────────────────────────────
  Future<void> _loadPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final url = doc.data()?['photoURL'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _photoURL = url);
      }
    } catch (_) {}
  }

  // ── Pick from gallery and upload to Cloudinary ───────────────────────────
  Future<void> _pickAndUpload() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await File(picked.path).readAsBytes();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'profile_pictures'
        ..fields['public_id'] = uid // same public_id = overwrites old photo
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '$uid.jpg',
        ));

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.body}');
      }

      final downloadURL =
      (jsonDecode(response.body) as Map<String, dynamic>)['secure_url']
      as String;

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoURL': downloadURL});

      if (mounted) {
        setState(() => _photoURL = downloadURL);
        _snack('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      if (mounted) _snack('Upload failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Avatar widget (shared between both circle placements) ────────────────
  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4A90FF), width: 3),
      ),
      child: ClipOval(
        child: _isUploading
            ? Container(
          color: Colors.black26,
          child: const Center(
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ),
        )
            : _photoURL != null
            ? Image.network(
          _photoURL!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/boy_avatar.png',
            fit: BoxFit.cover,
          ),
        )
            : Image.asset(
          'assets/images/boy_avatar.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile Picture ──────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  _buildAvatar(),
                  // Camera button
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUpload,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A90FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Menu Items ───────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF4A90FF)),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'My Info',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MyInfoScreen())),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen())),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen())),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen())),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    thickness: 1,
    color: Colors.white24,
    indent: 20,
    endIndent: 20,
  );

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen(role: 'teacher')),
                      (route) => false,
                );
              }
            },
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}