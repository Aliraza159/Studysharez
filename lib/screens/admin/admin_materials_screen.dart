// lib/screens/admin/admin_materials_screen.dart

import 'package:flutter/material.dart';
import '../../models/course_material_model.dart';
import '../../services/admin_service.dart';

class AdminMaterialsScreen extends StatefulWidget {
  const AdminMaterialsScreen({super.key});

  @override
  State<AdminMaterialsScreen> createState() => _AdminMaterialsScreenState();
}

class _AdminMaterialsScreenState extends State<AdminMaterialsScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
            () => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CourseMaterial> _applyFilters(List<CourseMaterial> all) {
    List<CourseMaterial> result = all;

    if (_typeFilter == 'PDF') {
      result = result.where((m) => m.fileType == 'pdf').toList();
    } else if (_typeFilter == 'PPT') {
      result = result.where((m) => m.fileType == 'ppt').toList();
    } else if (_typeFilter == 'DOC') {
      result = result.where((m) => m.fileType == 'doc').toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((m) {
        return m.title.toLowerCase().contains(_searchQuery) ||
            m.courseName.toLowerCase().contains(_searchQuery) ||
            m.teacherName.toLowerCase().contains(_searchQuery) ||
            m.courseCode.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  Future<void> _deleteMaterial(CourseMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Material'),
        content: Text(
            'Delete "${material.title}" from ${material.courseName}?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteMaterial(material.courseId, material.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Material deleted.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F2FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Materials',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                // Search
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(Icons.search,
                            color: Color(0xFF6B7280), size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by title, course or teacher',
                            hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 15),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xFF6B7280), size: 18),
                          onPressed: () => _searchController.clear(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Type filter chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'PDF', 'PPT', 'DOC']
                        .map((type) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _TypeChip(
                        label: type,
                        selected: _typeFilter == type,
                        onTap: () =>
                            setState(() => _typeFilter = type),
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<CourseMaterial>>(
              stream: _adminService.streamAllMaterials(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final all = snapshot.data ?? [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open_outlined,
                            size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No materials uploaded yet.',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Count header
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} file${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Tap 🗑 to delete',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.separated(
                        padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _AdminMaterialCard(
                            material: filtered[index],
                            onDelete: () =>
                                _deleteMaterial(filtered[index]),
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
    );
  }
}

// ─── Admin Material Card ──────────────────────────────────────────────────────
class _AdminMaterialCard extends StatelessWidget {
  final CourseMaterial material;
  final VoidCallback onDelete;

  const _AdminMaterialCard({
    required this.material,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _fileColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(), color: _fileColor(), size: 26),
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
                    fontSize: 14,
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
                            fontSize: 11, color: Color(0xFF6B7280)),
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
                            fontSize: 11, color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniTag(
                        label: material.fileType.toUpperCase(),
                        color: _fileColor()),
                    const SizedBox(width: 8),
                    Text(material.formattedSize,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text(material.formattedDate,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),

          // Delete
          IconButton(
            icon:
            const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
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

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF59E0B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}