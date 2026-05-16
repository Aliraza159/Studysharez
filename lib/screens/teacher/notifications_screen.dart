// lib/screens/teacher/notifications_screen.dart

import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _classReminders = true;
  bool _gradeUpdates = true;
  bool _announcements = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

            const SizedBox(height: 60),

            // Toggle Items
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildToggleTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      value: _pushNotifications,
                      onChanged: (val) =>
                          setState(() => _pushNotifications = val),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.email_outlined,
                      title: 'Email Alerts',
                      value: _emailAlerts,
                      onChanged: (val) => setState(() => _emailAlerts = val),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.alarm_outlined,
                      title: 'Class Reminders',
                      value: _classReminders,
                      onChanged: (val) =>
                          setState(() => _classReminders = val),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.grade_outlined,
                      title: 'Grade Updates',
                      value: _gradeUpdates,
                      onChanged: (val) => setState(() => _gradeUpdates = val),
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.campaign_outlined,
                      title: 'Announcements',
                      value: _announcements,
                      onChanged: (val) =>
                          setState(() => _announcements = val),
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Colors.white24,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
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