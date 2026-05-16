// lib/screens/teacher/teacher_files_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course_material_model.dart';

class TeacherFilesScreen extends StatefulWidget {
  const TeacherFilesScreen({super.key});

  @override
  State<TeacherFilesScreen> createState() => _TeacherFilesScreenState();
}

class _TeacherFilesScreenState extends State<TeacherFilesScreen> {
  bool _loading = true;
  String? _error;
  List<CourseMaterial> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // No indexes needed:
  // Step 1 — fetch teacher's courses (single-field where, no compound)
  // Step 2 — fetch materials/{courseId}/files for each course (no where at all)
  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'Not signed in.';
          _loading = false;
        });
        return;
      }

      final db = FirebaseFirestore.instance;

      // Step 1: get teacher's courses
      final coursesSnap = await db
          .collection('courses')
          .where('teacherId', isEqualTo: uid)
          .get();

      final List<CourseMaterial> allFiles = [];

      // Step 2: fetch files subcollection per course — zero indexes needed
      for (final courseDoc in coursesSnap.docs) {
        try {
          final filesSnap = await db
              .collection('materials')
              .doc(courseDoc.id)
              .collection('files')
              .get();

          for (final fileDoc in filesSnap.docs) {
            allFiles.add(CourseMaterial.fromMap(fileDoc.data(), fileDoc.id));
          }
        } catch (_) {
          continue;
        }
      }

      // Step 3: sort newest first in Dart
      allFiles.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      if (mounted) {
        setState(() {
          _files = allFiles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load files. Please try again.';
          _loading = false;
        });
      }
    }
  }

  // Open file URL in browser
  Future<void> _openFile(CourseMaterial material) async {
    if (material.fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File URL not available'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final uri = Uri.parse(material.fileUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open file'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  List<MapEntry<String, List<CourseMaterial>>> _groupByDate(
      List<CourseMaterial> files) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label(DateTime dt) {
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day == today) return 'Today';
      if (day == yesterday) return 'Yesterday';
      return DateFormat('d MMM yyyy').format(dt);
    }

    final Map<String, List<CourseMaterial>> map = {};
    final List<String> order = [];

    for (final f in files) {
      final l = label(f.uploadedAt);
      if (!order.contains(l)) order.add(l);
      map.putIfAbsent(l, () => []).add(f);
    }

    return order.map((l) => MapEntry(l, map[l]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Files',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All uploaded materials, organised by date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _loadFiles,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF4A90FF)),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A90FF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 52, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) return const _EmptyState();

    final grouped = _groupByDate(_files);

    return RefreshIndicator(
      color: const Color(0xFF4A90FF),
      onRefresh: _loadFiles,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final entry = grouped[i];
          return _DateSection(
            dateLabel: entry.key,
            files: entry.value,
            onTap: _openFile,
          );
        },
      ),
    );
  }
}

// ── Date Section ──────────────────────────────────────────────────────────────
class _DateSection extends StatelessWidget {
  final String dateLabel;
  final List<CourseMaterial> files;
  final Future<void> Function(CourseMaterial) onTap;

  const _DateSection({
    required this.dateLabel,
    required this.files,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(height: 1, color: const Color(0xFFCBD5E1)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...files.map((f) => _FileCard(material: f, onTap: onTap)),
      ],
    );
  }
}

// ── File Card ─────────────────────────────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final CourseMaterial material;
  final Future<void> Function(CourseMaterial) onTap;

  const _FileCard({required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _fileColor(material.fileType);
    final timeStr = DateFormat('hh:mm a').format(material.uploadedAt);

    return GestureDetector(
      onTap: () => onTap(material),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── File type icon ──────────────────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(_fileIcon(material.fileType), color: color, size: 26),
            ),

            const SizedBox(width: 14),

            // ── Info ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (material.courseName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      material.courseName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A90FF),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      if (material.fileSize > 0) ...[
                        const SizedBox(width: 8),
                        const Text('·',
                            style:
                            TextStyle(color: Color(0xFF9CA3AF))),
                        const SizedBox(width: 8),
                        Text(
                          material.formattedSize,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Open icon ───────────────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.open_in_new_rounded, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF97316);
      case 'doc':
      case 'docx':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                size: 44, color: Color(0xFF4A90FF)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No files uploaded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Materials you upload will appear here,\norganised by date.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}