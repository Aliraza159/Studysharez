// lib/screens/admin/admin_courses_screen.dart

import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/admin_service.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  List<Course> _applySearch(List<Course> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.code.toLowerCase().contains(_searchQuery) ||
          c.semester.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openCourseForm({Course? course}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourseFormSheet(
        adminService: _adminService,
        existingCourse: course,
        onSaved: () {
          Navigator.pop(context);
          _showSnackBar(
            course == null
                ? 'Course created successfully!'
                : 'Course updated successfully!',
            Colors.green,
          );
        },
      ),
    );
  }

  Future<void> _deleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Course'),
        content: Text(
          'Delete "${course.name}"?\n\nThis will also delete ALL materials uploaded to this course. This cannot be undone.',
        ),
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
        await _adminService.deleteCourse(course.id);
        if (mounted) _showSnackBar('Course deleted.', Colors.green);
      } catch (e) {
        if (mounted) _showSnackBar('Delete failed: $e', Colors.red);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F2FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Courses',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openCourseForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
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
                        hintText: 'Search courses...',
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
          ),

          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _adminService.streamAllCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                final all = snapshot.data ?? [];
                final filtered = _applySearch(all);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        const Text('No courses found.',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 15)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openCourseForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Course'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return _CourseCard(
                      course: course,
                      onEdit: () => _openCourseForm(course: course),
                      onDelete: () => _deleteCourse(course),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.book_rounded,
                color: Color(0xFF10B981), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Badge(label: course.code, color: const Color(0xFF4A90FF)),
                    const SizedBox(width: 8),
                    _Badge(
                        label: course.semester,
                        color: const Color(0xFF8B5CF6)),
                  ],
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF4A90FF), size: 20),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ─── Course Form Bottom Sheet ─────────────────────────────────────────────────
class _CourseFormSheet extends StatefulWidget {
  final AdminService adminService;
  final Course? existingCourse;
  final VoidCallback onSaved;

  const _CourseFormSheet({
    required this.adminService,
    required this.onSaved,
    this.existingCourse,
  });

  @override
  State<_CourseFormSheet> createState() => _CourseFormSheetState();
}

class _CourseFormSheetState extends State<_CourseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _semesterController = TextEditingController();

  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId;
  bool _isLoading = false;
  bool _teachersLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingCourse != null) {
      _nameController.text = widget.existingCourse!.name;
      _codeController.text = widget.existingCourse!.code;
      _semesterController.text = widget.existingCourse!.semester;
      _selectedTeacherId = widget.existingCourse!.teacherId;
    }
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await widget.adminService.getTeachers();
    if (mounted) {
      setState(() {
        _teachers = teachers;
        _teachersLoading = false;
        if (_selectedTeacherId == null && teachers.isNotEmpty) {
          _selectedTeacherId = teachers.first['id'];
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a teacher'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.existingCourse == null) {
        await widget.adminService.createCourse(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          semester: _semesterController.text.trim(),
          teacherId: _selectedTeacherId!,
        );
      } else {
        await widget.adminService.updateCourse(
          courseId: widget.existingCourse!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          semester: _semesterController.text.trim(),
          teacherId: _selectedTeacherId!,
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCourse != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isEditing ? 'Edit Course' : 'Create New Course',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 20),

            // Course Name
            _FormField(
              controller: _nameController,
              label: 'Course Name',
              hint: 'e.g. Operating Systems',
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 14),

            // Code + Semester row
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _codeController,
                    label: 'Course Code',
                    hint: 'e.g. CS401',
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    controller: _semesterController,
                    label: 'Semester',
                    hint: 'e.g. 4th Semester',
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Teacher Dropdown
            const Text(
              'Assign Teacher',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _teachersLoading
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Loading teachers...',
                        style:
                        TextStyle(color: Color(0xFF9CA3AF))),
                  ],
                ),
              )
                  : _teachers.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No teachers found. First assign "teacher" role to a user.',
                  style: TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              )
                  : DropdownButtonFormField<String>(
                value: _selectedTeacherId,
                decoration: const InputDecoration(
                    border: InputBorder.none),
                isExpanded: true,
                hint: const Text('Select teacher',
                    style:
                    TextStyle(color: Color(0xFF9CA3AF))),
                items: _teachers.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id'] as String,
                    child: Text(
                      t['name'] ?? t['email'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => _selectedTeacherId = val),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
                    : Text(
                  isEditing ? 'Save Changes' : 'Create Course',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?) validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}