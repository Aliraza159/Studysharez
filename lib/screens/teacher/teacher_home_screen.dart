// lib/screens/teacher/teacher_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/student/student_home_screen.dart';
import 'teacher_courses_screen.dart';
import 'upload_material_screen.dart';
import 'teacher_files_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) => setState(() => _currentIndex = index);

  List<Widget> get _screens => [
    TeacherHomeContent(onSwitchTab: _switchTab),
    const TeacherCoursesScreen(),
    const UploadMaterialScreen(),
    const TeacherFilesScreen(),
    const TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.book, label: 'Courses', index: 1),
                _buildUploadButton(),
                _buildNavItem(icon: Icons.file_copy, label: 'Files', index: 3),
                _buildNavItem(icon: Icons.person, label: 'Profile', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF4A90FF)
                    : const Color(0xFF6B7280)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF4A90FF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _switchTab(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.cloud_upload,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFF4A90FF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEACHER HOME CONTENT
// ============================================================
class TeacherHomeContent extends StatefulWidget {
  /// Callback to switch the bottom nav tab from this widget.
  /// Index 1 = Courses, Index 3 = Files
  final void Function(int index) onSwitchTab;

  const TeacherHomeContent({super.key, required this.onSwitchTab});

  @override
  State<TeacherHomeContent> createState() => _TeacherHomeContentState();
}

class _TeacherHomeContentState extends State<TeacherHomeContent> {
  String _teacherName = 'Professor';
  bool _nameLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  Future<void> _fetchTeacherName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _nameLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (mounted) {
        final data = doc.data();
        final name = data?['name'] ??
            data?['displayName'] ??
            data?['fullName'] ??
            'Professor';
        setState(() {
          _teacherName = name as String;
          _nameLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _nameLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen())),
            child:
             Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF4A90FF), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/boy_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameLoading
                            ? Container(
                          width: 180,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                            : Text(
                          'Hi, $_teacherName',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Here's your teaching overview",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            // ── Content ─────────────────────────────────────────────────
            Container(
              color: const Color(0xFFE3F2FD),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Courses card → switches to Courses tab (index 1)
                  _buildActionCard(
                    title: 'Courses',
                    subtitle: 'Browse your assigned subjects',
                    buttonText: 'Browse',
                    illustration: 'assets/images/girl_illustration.png',
                    onTap: () => widget.onSwitchTab(1),
                  ),

                  const SizedBox(height: 20),

                  // My Files card → switches to Files tab (index 3)
                  _buildActionCard(
                    title: 'My Files',
                    subtitle: 'View or manage your files',
                    buttonText: 'Browse',
                    illustration: 'assets/images/cloud_illustration.png',
                    onTap: () => widget.onSwitchTab(3),
                  ),

                  const SizedBox(height: 20),

                  // ── Live Announcements ──────────────────────────────
                  const AnnouncementsSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required String illustration,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCEEFF), Color(0xFFE3F2FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            illustration,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}