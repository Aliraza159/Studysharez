// lib/screens/student/student_notifications_screen.dart

import 'package:flutter/material.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  // ── General ──────────────────────────────────────────────
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  // ── Academic ─────────────────────────────────────────────
  bool _newMaterials = true;
  bool _assignmentDue = true;
  bool _gradeReleased = true;

  // ── Social ────────────────────────────────────────────────
  bool _announcements = false;
  bool _libraryUpdates = false;

  bool _isSaving = false;

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    // Simulate saving to backend / shared prefs
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with real persistence, e.g.:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('push_notifications', _pushNotifications);
    // ... etc.

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification preferences saved!'),
          backgroundColor: const Color(0xFF4A90FF),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1A1A2E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    // ── General ──────────────────────────────
                    _buildSectionHeader('General'),
                    _buildToggleTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts on your device',
                      value: _pushNotifications,
                      onChanged: (v) =>
                          setState(() => _pushNotifications = v),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.email_outlined,
                      title: 'Email Alerts',
                      subtitle: 'Get updates in your inbox',
                      value: _emailAlerts,
                      onChanged: (v) => setState(() => _emailAlerts = v),
                    ),

                    const SizedBox(height: 24),

                    // ── Academic ─────────────────────────────
                    _buildSectionHeader('Academic'),
                    _buildToggleTile(
                      icon: Icons.menu_book_outlined,
                      title: 'New Materials',
                      subtitle: 'Notified when a teacher uploads',
                      value: _newMaterials,
                      onChanged: (v) => setState(() => _newMaterials = v),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.assignment_outlined,
                      title: 'Assignment Due',
                      subtitle: 'Reminders before deadlines',
                      value: _assignmentDue,
                      onChanged: (v) => setState(() => _assignmentDue = v),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.grade_outlined,
                      title: 'Grade Released',
                      subtitle: 'Alert when results are posted',
                      value: _gradeReleased,
                      onChanged: (v) => setState(() => _gradeReleased = v),
                    ),

                    const SizedBox(height: 24),

                    // ── Social ────────────────────────────────
                    _buildSectionHeader('Social'),
                    _buildToggleTile(
                      icon: Icons.campaign_outlined,
                      title: 'Announcements',
                      subtitle: 'From admins & instructors',
                      value: _announcements,
                      onChanged: (v) => setState(() => _announcements = v),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.local_library_outlined,
                      title: 'Library Updates',
                      subtitle: 'New books or resources added',
                      value: _libraryUpdates,
                      onChanged: (v) => setState(() => _libraryUpdates = v),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4A90FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF4A90FF),
                          ),
                        )
                            : const Text(
                          'Save Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Colors.white24,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white38,
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}