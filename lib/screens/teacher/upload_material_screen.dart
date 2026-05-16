// lib/screens/teacher/upload_material_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/course_model.dart';
import '../../services/material_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadMaterialScreen extends StatefulWidget {
  final Course? preSelectedCourse;

  const UploadMaterialScreen({
    super.key,
    this.preSelectedCourse,
  });

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialService = MaterialService();

  Course? _selectedCourse;
  List<Course> _courses = [];
  bool _coursesLoading = true;

  File? _selectedFile;
  String? _fileName;
  String? _fileType;
  int? _fileSize;

  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();

    // If a course was passed in, use it immediately — no loading needed
    if (widget.preSelectedCourse != null) {
      _selectedCourse = widget.preSelectedCourse;
      _courses = [widget.preSelectedCourse!];
      _coursesLoading = false;
    } else {
      _loadCourses();
    }
  }

  // Only called when no preSelectedCourse is given (standalone upload screen)
  Future<void> _loadCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _coursesLoading = false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('courses')
          .where('teacherId', isEqualTo: uid)
          .get();

      final courses = snap.docs
          .map((doc) => Course.fromMap(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _courses = courses;
          if (courses.isNotEmpty) _selectedCourse = courses.first;
          _coursesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _coursesLoading = false);
        _showSnackBar('Failed to load courses: $e', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size;
          _fileType =
              _getFileType(result.files.single.extension?.toLowerCase());
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', Colors.red);
    }
  }

  String _getFileType(String? ext) {
    if (ext == 'pdf') return 'pdf';
    if (ext == 'ppt' || ext == 'pptx') return 'ppt';
    if (ext == 'doc' || ext == 'docx') return 'doc';
    return 'other';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourse == null) {
      _showSnackBar('Please select a course', Colors.red);
      return;
    }
    if (_selectedFile == null) {
      _showSnackBar('Please select a file to upload', Colors.red);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await _materialService.uploadMaterial(
        course: _selectedCourse!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        file: _selectedFile!,
        fileName: _fileName!,
        fileType: _fileType!,
        fileSize: _fileSize!,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      if (!mounted) return;
      _showSnackBar('Material uploaded successfully!', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Upload failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Material',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            Text(
              'Add new notes or files for your students',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Course Dropdown ──────────────────────────────────────
                _label('Course'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: _coursesLoading
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading courses...',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  )
                      : _courses.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No courses assigned to you yet.\nAsk admin to assign courses.',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13),
                    ),
                  )
                      : DropdownButtonFormField<Course>(
                    value: _selectedCourse,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Select a course',
                      hintStyle:
                      TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    isExpanded: true,
                    items: _courses.map((course) {
                      return DropdownMenuItem<Course>(
                        value: course,
                        child: Text(
                          '${course.name} (${course.code})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.preSelectedCourse != null
                        ? null // Lock dropdown if course pre-selected
                        : (value) => setState(
                            () => _selectedCourse = value),
                    validator: (value) => value == null
                        ? 'Please select a course'
                        : null,
                  ),
                ),

                // Show locked course info if pre-selected
                if (widget.preSelectedCourse != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        'Uploading to: ${widget.preSelectedCourse!.name}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────────────
                _label('Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                      'e.g. Lecture 5 – Process Scheduling'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please enter a title'
                      : null,
                ),

                const SizedBox(height: 24),

                // ── Description ──────────────────────────────────────────
                _label('Description (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration:
                  _inputDecoration('Add a short description...'),
                ),

                const SizedBox(height: 24),

                // ── File Picker ──────────────────────────────────────────
                _label('File'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFile != null
                            ? const Color(0xFF4A90FF)
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: _selectedFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap to upload file',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PDF, PPT, DOC allowed',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280)),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getFileIcon(),
                            size: 48, color: _getFileColor()),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Text(
                            _fileName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatFileSize(_fileSize!),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed:
                          _isUploading ? null : _pickFile,
                          icon: const Icon(Icons.refresh,
                              size: 16),
                          label: const Text('Change File'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                            const Color(0xFF4A90FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Upload Progress ──────────────────────────────────────
                if (_isUploading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A90FF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Upload Button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isUploading || _courses.isEmpty)
                        ? null
                        : _uploadMaterial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor:
                      const Color(0xFF4A90FF).withOpacity(0.6),
                    ),
                    child: _isUploading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading...',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                        : const Text(
                      'Upload Material',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
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

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A2E),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
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
      borderSide: const BorderSide(color: Color(0xFF4A90FF)),
    ),
  );

  IconData _getFileIcon() {
    switch (_fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
        return Icons.slideshow;
      default:
        return Icons.description;
    }
  }

  Color _getFileColor() {
    switch (_fileType) {
      case 'pdf':
        return Colors.red;
      case 'ppt':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}