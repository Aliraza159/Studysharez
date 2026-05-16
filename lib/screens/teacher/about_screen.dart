// lib/screens/teacher/about_screen.dart

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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

            const SizedBox(height: 20),

            // App Logo / Icon area
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'EduApp',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Info tiles
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildInfoTile(
                      icon: Icons.verified_outlined,
                      title: 'App Version',
                      value: '1.0.0',
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.build_outlined,
                      title: 'Build Number',
                      value: '100',
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.developer_mode_outlined,
                      title: 'Developer',
                      value: 'EduTech Solutions',
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy Policy',
                      value: 'View',
                      isLink: true,
                      onTap: () {
                        // TODO: Open privacy policy
                      },
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms of Service',
                      value: 'View',
                      isLink: true,
                      onTap: () {
                        // TODO: Open terms
                      },
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
    bool isLink = false,
    VoidCallback? onTap,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: isLink ? Colors.white : Colors.white70,
                  decoration:
                  isLink ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
              if (isLink) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}