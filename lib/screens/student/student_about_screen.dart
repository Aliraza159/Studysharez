// lib/screens/student/student_about_screen.dart
//
// Dependencies: none (url_launcher is optional — see TODO comments)
// If you add url_launcher to pubspec.yaml you can uncomment the launch() calls.

import 'package:flutter/material.dart';

class StudentAboutScreen extends StatelessWidget {
  const StudentAboutScreen({super.key});

  // App constants — update these as needed
  static const String _appName = 'StudyShareZ';
  static const String _version = '1.0.0';
  static const String _buildNumber = '100';
  static const String _developer = 'EduTech Solutions';
  static const String _supportEmail = 'support@studysharez.com';
  static const String _privacyUrl = 'https://studysharez.com/privacy';
  static const String _termsUrl = 'https://studysharez.com/terms';

  void _openLink(BuildContext context, String url) {
    // TODO: Add url_launcher to pubspec.yaml and uncomment:
    // launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    // Fallback: show a dialog with the URL
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Open Link'),
        content: Text(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    _openLink(context, 'mailto:$_supportEmail');
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
                    'About',
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

            // App icon + name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    _appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version $_version',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Content list
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
                  padding: const EdgeInsets.only(top: 10),
                  children: [
                    // App info tiles (read-only)
                    _buildInfoTile(
                      icon: Icons.verified_outlined,
                      title: 'Version',
                      value: _version,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.build_outlined,
                      title: 'Build Number',
                      value: _buildNumber,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.developer_mode_outlined,
                      title: 'Developer',
                      value: _developer,
                    ),
                    _buildDivider(),

                    // Tappable tiles
                    _buildLinkTile(
                      icon: Icons.email_outlined,
                      title: 'Contact Support',
                      value: _supportEmail,
                      onTap: () => _sendEmail(context),
                    ),
                    _buildDivider(),
                    _buildLinkTile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy Policy',
                      value: 'View',
                      onTap: () => _openLink(context, _privacyUrl),
                    ),
                    _buildDivider(),
                    _buildLinkTile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms of Service',
                      value: 'View',
                      onTap: () => _openLink(context, _termsUrl),
                    ),
                    _buildDivider(),

                    // Acknowledgement
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Text(
                        '© 2024 EduTech Solutions. All rights reserved.\n'
                            'Made with ❤️ for students.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                          height: 1.6,
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

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Colors.white24,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String value,
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}