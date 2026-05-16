// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_service.dart';
import '../../services/announcement_service.dart';
import 'admin_users_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_materials_screen.dart';
import 'admin_announcements_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _adminService = AdminService();
  final _announcementService = AnnouncementService();
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _adminName = 'Admin';
  int _announcementCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _announcementService.streamAnnouncements().listen((list) {
      if (mounted) setState(() => _announcementCount = list.length);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _stats = stats;
          _adminName = user?.displayName ?? user?.email ?? 'Admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(role: 'student'),
          ),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, $_adminName',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.red, size: 22),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Stats Overview ────────────────────────────────────────
                _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : _buildStatsSection(),

                const SizedBox(height: 28),

                // ── Quick Actions ─────────────────────────────────────────
                const Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),

                const SizedBox(height: 16),

                _ActionCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Users',
                  subtitle: 'Manage students, teachers & admins',
                  count: '${_stats['totalUsers'] ?? 0} users',
                  color: const Color(0xFF4A90FF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen()),
                  ).then((_) => _loadData()),
                ),

                const SizedBox(height: 16),

                _ActionCard(
                  icon: Icons.school_rounded,
                  title: 'Courses',
                  subtitle: 'Create, edit & assign courses to teachers',
                  count: '${_stats['courses'] ?? 0} courses',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminCoursesScreen()),
                  ).then((_) => _loadData()),
                ),

                const SizedBox(height: 16),

                _ActionCard(
                  icon: Icons.folder_rounded,
                  title: 'Materials',
                  subtitle: 'View & delete any uploaded material',
                  count: '${_stats['materials'] ?? 0} files',
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminMaterialsScreen()),
                  ).then((_) => _loadData()),
                ),

                const SizedBox(height: 16),

                _ActionCard(
                  icon: Icons.campaign_rounded,
                  title: 'Announcements',
                  subtitle: 'Post updates visible to all students & teachers',
                  count: '$_announcementCount posted',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAnnouncementsScreen()),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Role Breakdown ────────────────────────────────────────
                const Text(
                  'User Breakdown',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),

                const SizedBox(height: 16),

                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          child: _RoleCount(
                            label: 'Students',
                            count: _stats['students'] ?? 0,
                            color: const Color(0xFF4A90FF),
                            icon: Icons.person_outline,
                          ),
                        ),
                        _divider(),
                        Expanded(
                          child: _RoleCount(
                            label: 'Teachers',
                            count: _stats['teachers'] ?? 0,
                            color: const Color(0xFF10B981),
                            icon: Icons.school_outlined,
                          ),
                        ),
                        _divider(),
                        Expanded(
                          child: _RoleCount(
                            label: 'Admins',
                            count: _stats['admins'] ?? 0,
                            color: const Color(0xFFF59E0B),
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── FIX: Replaced GridView with a custom 2-column layout using
  // IntrinsicHeight rows so cards size to their content instead of
  // a fixed childAspectRatio that caused the 8.4px overflow.
  Widget _buildStatsSection() {
    final cards = [
      _StatCard(
        label: 'Total Users',
        value: '${_stats['totalUsers'] ?? 0}',
        icon: Icons.people_rounded,
        gradient: const [Color(0xFF4A90FF), Color(0xFF357AE8)],
      ),
      _StatCard(
        label: 'Courses',
        value: '${_stats['courses'] ?? 0}',
        icon: Icons.book_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
      ),
      _StatCard(
        label: 'Materials',
        value: '${_stats['materials'] ?? 0}',
        icon: Icons.insert_drive_file_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      _StatCard(
        label: 'Teachers',
        value: '${_stats['teachers'] ?? 0}',
        icon: Icons.school_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
    ];

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 50,
    color: const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ── FIX: removed fixed height; card now sizes to its content.
      // Added symmetric vertical padding so the Column breathes
      // without overflowing on small screens.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // ── FIX: changed mainAxisAlignment from spaceBetween to start
        // and added a fixed SizedBox gap so the layout is explicit
        // and never relies on the container having a specific height.
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─── Role Count ───────────────────────────────────────────────────────────────
class _RoleCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _RoleCount({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}