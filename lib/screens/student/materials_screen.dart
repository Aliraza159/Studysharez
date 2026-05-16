// lib/screens/student/materials_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course_material_model.dart';
import '../../services/material_service.dart';
import 'library_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _materialService = MaterialService();
  final _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  // Track which files are currently downloading and their progress
  final Map<String, double> _downloadProgress = {};

  // Track which files are already downloaded
  final Set<String> _downloadedIds = {};

  // Prevents _checkDownloadedStatus from running on every rebuild
  bool _statusChecked = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Only runs once on first load, and again after each download
  Future<void> _checkDownloadedStatus(List<CourseMaterial> materials) async {
    if (_statusChecked) return;
    _statusChecked = true;

    for (final m in materials) {
      final downloaded = await DownloadService.isDownloaded(m);
      if (downloaded && mounted) {
        setState(() => _downloadedIds.add(m.id));
      }
    }
  }

  List<CourseMaterial> _applyFilters(List<CourseMaterial> all) {
    List<CourseMaterial> result = all;

    if (_selectedFilter == "PDF's") {
      result = result.where((m) => m.fileType == 'pdf').toList();
    } else if (_selectedFilter == 'Slides') {
      result = result.where((m) => m.fileType == 'ppt').toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((m) {
        return m.title.toLowerCase().contains(_searchQuery) ||
            m.courseName.toLowerCase().contains(_searchQuery) ||
            m.courseCode.toLowerCase().contains(_searchQuery) ||
            m.teacherName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  Future<void> _openFile(CourseMaterial material) async {
    // If already downloaded open from local storage
    if (_downloadedIds.contains(material.id)) {
      await DownloadService.openFile(material);
      return;
    }
    // Otherwise open from Cloudinary URL
    try {
      final uri = Uri.parse(material.fileUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not open file.', Colors.red);
      }
    }
  }

  Future<void> _downloadFile(CourseMaterial material) async {
    if (_downloadProgress.containsKey(material.id)) return;

    setState(() => _downloadProgress[material.id] = 0.0);

    try {
      await DownloadService.download(
        material: material,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress[material.id] = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(material.id);
          _downloadedIds.add(material.id);
          // Reset flag so the newly downloaded file is rechecked next rebuild
          _statusChecked = false;
        });
        _showSnackBar(
            '✓ "${material.title}" saved to Library!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(material.id));
        _showSnackBar('Download failed: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Materials',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
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
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.search,
                          color: Color(0xFF6B7280), size: 24),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search materials or courses',
                          hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF6B7280), size: 20),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Single StreamBuilder for everything ───────────────────────
            Expanded(
              child: StreamBuilder<List<CourseMaterial>>(
                stream: _materialService.streamAllMaterials(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 56, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading materials.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final filtered = _applyFilters(all);
                  final pdfCount =
                      all.where((m) => m.fileType == 'pdf').length;
                  final pptCount =
                      all.where((m) => m.fileType == 'ppt').length;

                  // Only check downloaded status once, not on every rebuild
                  if (!_statusChecked) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _checkDownloadedStatus(all);
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quick Access Cards ──────────────────────────────
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickCard(
                                label: "PDF's",
                                count: pdfCount,
                                color: Colors.red,
                                icon: Icons.picture_as_pdf,
                                onTap: () => setState(
                                      () => _selectedFilter =
                                  _selectedFilter == "PDF's"
                                      ? 'All'
                                      : "PDF's",
                                ),
                                isActive: _selectedFilter == "PDF's",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _QuickCard(
                                label: "PPT's",
                                count: pptCount,
                                color: Colors.orange,
                                icon: Icons.slideshow,
                                onTap: () => setState(
                                      () => _selectedFilter =
                                  _selectedFilter == 'Slides'
                                      ? 'All'
                                      : 'Slides',
                                ),
                                isActive: _selectedFilter == 'Slides',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Filter Chips ────────────────────────────────────
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _selectedFilter == 'All',
                              onTap: () => setState(
                                      () => _selectedFilter = 'All'),
                            ),
                            const SizedBox(width: 12),
                            _FilterChip(
                              label: "PDF's",
                              selected: _selectedFilter == "PDF's",
                              onTap: () => setState(
                                      () => _selectedFilter = "PDF's"),
                            ),
                            const SizedBox(width: 12),
                            _FilterChip(
                              label: 'Slides',
                              selected: _selectedFilter == 'Slides',
                              onTap: () => setState(
                                      () => _selectedFilter = 'Slides'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Browse Materials Header ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Browse Materials',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              '${filtered.length} file${filtered.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Materials List ───────────────────────────────────
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.folder_open_outlined,
                                  size: 64,
                                  color: Color(0xFF9CA3AF)),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No results for "$_searchQuery"'
                                    : 'No materials available yet.',
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        )
                            : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 20),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final material = filtered[index];
                            return _MaterialCard(
                              material: material,
                              isDownloaded: _downloadedIds
                                  .contains(material.id),
                              downloadProgress:
                              _downloadProgress[material.id],
                              onTap: () => _openFile(material),
                              onDownload: () =>
                                  _downloadFile(material),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Access Card ────────────────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _QuickCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [color, color.withOpacity(0.7)]
                : [const Color(0xFF4A90FF), const Color(0xFF357AE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isActive ? color : const Color(0xFF4A90FF))
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  Text('$count files',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A90FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

// ─── Material Card with Download Button ──────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final CourseMaterial material;
  final bool isDownloaded;
  final double? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _MaterialCard({
    required this.material,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Row(
              children: [
                // File type icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _fileColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                  Icon(_fileIcon(), color: _fileColor(), size: 28),
                ),
                const SizedBox(width: 12),

                // Info
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
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              material.teacherName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.book_outlined,
                              size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${material.courseCode} · ${material.courseName}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Tag(
                            label: material.fileType.toUpperCase(),
                            color: _fileColor(),
                          ),
                          const SizedBox(width: 8),
                          Text(material.formattedSize,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280))),
                          const Spacer(),
                          Text(material.formattedDate,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action buttons column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Open button
                    IconButton(
                      icon: const Icon(Icons.open_in_new,
                          size: 18, color: Color(0xFF4A90FF)),
                      onPressed: onTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      tooltip: 'Open',
                    ),

                    const SizedBox(height: 4),

                    // Download / Downloading / Downloaded indicator
                    isDownloading
                        ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        strokeWidth: 2.5,
                        color: const Color(0xFF4A90FF),
                      ),
                    )
                        : isDownloaded
                        ? const Tooltip(
                      message: 'Saved to Library',
                      child: Icon(
                        Icons.download_done_rounded,
                        size: 22,
                        color: Colors.green,
                      ),
                    )
                        : IconButton(
                      icon: const Icon(
                        Icons.download_outlined,
                        size: 22,
                        color: Color(0xFF4A90FF),
                      ),
                      onPressed: onDownload,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      tooltip: 'Save to Library',
                    ),
                  ],
                ),
              ],
            ),

            // Download progress bar shown below the row
            if (isDownloading) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloadProgress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A90FF)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Downloading ${((downloadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _fileIcon() {
    switch (material.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
        return Icons.slideshow;
      default:
        return Icons.description;
    }
  }

  Color _fileColor() {
    switch (material.fileType) {
      case 'pdf':
        return Colors.red;
      case 'ppt':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

// ─── Tag ──────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}