// lib/screens/student/library_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/course_material_model.dart';

class DownloadService {
  static Future<Directory> _baseDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final base = Directory('${appDir.path}/StudySharez');
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  static Future<Directory> courseDir(CourseMaterial material) async {
    final base = await _baseDir();
    final folderName =
    '${material.courseCode}_${material.courseName}'.replaceAll(' ', '_');
    final dir = Directory('${base.path}/$folderName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> filePath(CourseMaterial material) async {
    final dir = await courseDir(material);
    return '${dir.path}/${material.fileName}';
  }

  static Future<bool> isDownloaded(CourseMaterial material) async {
    final path = await filePath(material);
    return File(path).exists();
  }

  static Future<void> download({
    required CourseMaterial material,
    required Function(double) onProgress,
  }) async {
    final path = await filePath(material);
    final file = File(path);

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(material.fileUrl));
    final response = await client.send(request);

    final total = response.contentLength ?? 0;
    int received = 0;

    final sink = file.openWrite();
    await response.stream.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress(received / total);
    }).asFuture();

    await sink.flush();
    await sink.close();
    client.close();
  }

  static Future<void> deleteFile(CourseMaterial material) async {
    final path = await filePath(material);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> openFile(CourseMaterial material) async {
    final path = await filePath(material);
    await OpenFilex.open(path);
  }

  static Future<Map<String, List<_LocalFile>>> getAllDownloaded() async {
    final base = await _baseDir();
    final Map<String, List<_LocalFile>> result = {};

    if (!await base.exists()) return result;

    await for (final entity in base.list()) {
      if (entity is Directory) {
        final courseName = entity.path.split('/').last;
        final files = <_LocalFile>[];

        await for (final file in entity.list()) {
          if (file is File) {
            final stat = await file.stat();
            files.add(_LocalFile(
              path: file.path,
              name: file.path.split('/').last,
              size: stat.size,
              modifiedAt: stat.modified,
            ));
          }
        }

        if (files.isNotEmpty) {
          files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
          result[courseName] = files;
        }
      }
    }

    return result;
  }

  static Future<Map<String, dynamic>> getStats() async {
    final downloaded = await getAllDownloaded();
    int count = 0;
    int totalSize = 0;
    for (final files in downloaded.values) {
      count += files.length;
      totalSize += files.fold(0, (sum, f) => sum + f.size);
    }
    return {'count': count, 'size': totalSize};
  }
}

class _LocalFile {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedAt;

  _LocalFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedAt,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileType {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (ext == 'ppt' || ext == 'pptx') return 'ppt';
    if (ext == 'doc' || ext == 'docx') return 'doc';
    return 'other';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(modifiedAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${modifiedAt.day}/${modifiedAt.month}/${modifiedAt.year}';
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  Map<String, List<_LocalFile>> _downloadedFiles = {};
  Map<String, dynamic> _stats = {'count': 0, 'size': 0};
  bool _isLoading = true;

  final Set<String> _expandedCourses = {};

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoading = true);
    final files = await DownloadService.getAllDownloaded();
    final stats = await DownloadService.getStats();
    if (mounted) {
      setState(() {
        _downloadedFiles = files;
        _stats = stats;
        _isLoading = false;
        _expandedCourses.addAll(files.keys);
      });
    }
  }

  Future<void> _openFile(_LocalFile file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: ${result.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteFile(_LocalFile file, String courseKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File'),
        content: Text(
            'Remove "${file.name}" from your library? You can download it again from Materials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await File(file.path).delete();
      await _loadLibrary();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File removed from library.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatCourseTitle(String folderName) {
    final parts = folderName.split('_');
    if (parts.length > 1) {
      final code = parts.first;
      final name = parts.sublist(1).join(' ');
      return '$code · $name';
    }
    return folderName.replaceAll('_', ' ');
  }

  String _formatTotalSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'My Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadLibrary,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF4A90FF), size: 26),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_downloadedFiles.isEmpty)
              _buildEmptyState()
            else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsCard(),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Downloaded Files',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadLibrary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _downloadedFiles.keys.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final courseKey =
                        _downloadedFiles.keys.elementAt(index);
                        final files = _downloadedFiles[courseKey]!;
                        final isExpanded =
                        _expandedCourses.contains(courseKey);

                        return _CourseFolderCard(
                          courseKey: courseKey,
                          courseTitle: _formatCourseTitle(courseKey),
                          files: files,
                          isExpanded: isExpanded,
                          onToggle: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedCourses.remove(courseKey);
                              } else {
                                _expandedCourses.add(courseKey);
                              }
                            });
                          },
                          onOpenFile: _openFile,
                          onDeleteFile: (file) =>
                              _deleteFile(file, courseKey),
                        );
                      },
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final count = _stats['count'] as int;
    final size = _stats['size'] as int;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90FF), Color(0xFF357AE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90FF).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Files',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Storage',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatTotalSize(size),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_rounded,
                color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.download_for_offline_outlined,
                    size: 52, color: Color(0xFF4A90FF)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Library is Empty',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Files you download from Materials\nwill appear here, organized by course.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseFolderCard extends StatelessWidget {
  final String courseKey;
  final String courseTitle;
  final List<_LocalFile> files;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(_LocalFile) onOpenFile;
  final Function(_LocalFile) onDeleteFile;

  const _CourseFolderCard({
    required this.courseKey,
    required this.courseTitle,
    required this.files,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpenFile,
    required this.onDeleteFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: Color(0xFF4A90FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          courseTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${files.length} file${files.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF6B7280), size: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                ...files.map((file) => _FileRow(
                  file: file,
                  onOpen: () => onOpenFile(file),
                  onDelete: () => onDeleteFile(file),
                  isLast: file == files.last,
                )),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final _LocalFile file;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool isLast;

  const _FileRow({
    required this.file,
    required this.onOpen,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _fileColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  Icon(_fileIcon(), color: _fileColor(), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MiniChip(
                              label: file.fileType.toUpperCase(),
                              color: _fileColor()),
                          Text(file.formattedSize,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280))),
                          Text('·',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400])),
                          Text(file.formattedDate,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new,
                        size: 18, color: Color(0xFF4A90FF)),
                    onPressed: onOpen,
                    tooltip: 'Open',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              indent: 62,
              endIndent: 12,
              color: Color(0xFFE5E7EB)),
      ],
    );
  }

  IconData _fileIcon() {
    switch (file.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
        return Icons.slideshow;
      default:
        return Icons.description;
    }
  }

  Color _fileColor() {
    switch (file.fileType) {
      case 'pdf':
        return Colors.red;
      case 'ppt':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}