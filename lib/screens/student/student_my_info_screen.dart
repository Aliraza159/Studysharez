// lib/screens/student/student_my_info_screen.dart

import 'package:flutter/material.dart';

class StudentMyInfoScreen extends StatefulWidget {
  const StudentMyInfoScreen({super.key});

  @override
  State<StudentMyInfoScreen> createState() => _StudentMyInfoScreenState();
}

class _StudentMyInfoScreenState extends State<StudentMyInfoScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  // Controllers pre-filled with dummy data (replace with real user data)
  final _nameController = TextEditingController(text: 'Ali Raza');
  final _emailController = TextEditingController(text: 'ali.raza@uni.edu.pk');
  final _phoneController = TextEditingController(text: '+92 300 1234567');
  final _rollController = TextEditingController(text: 'CS-2021-0042');
  final _semesterController = TextEditingController(text: '4');
  final _departmentController = TextEditingController(text: 'Computer Science');

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollController.dispose();
    _semesterController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulate a network/DB save delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with real save logic, e.g.:
    // await UserRepository.updateProfile(name: _nameController.text, ...);

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: const Color(0xFF4A90FF),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    // Reset controllers to last saved values if needed
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
                  const Expanded(
                    child: Text(
                      'My Info',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  // Edit / Cancel button
                  TextButton.icon(
                    onPressed: () {
                      if (_isEditing) {
                        _cancelEdit();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit_outlined,
                      size: 18,
                      color: const Color(0xFF4A90FF),
                    ),
                    label: Text(
                      _isEditing ? 'Cancel' : 'Edit',
                      style: const TextStyle(
                        color: Color(0xFF4A90FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4A90FF),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/boy_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A90FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Form
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: [
                      _buildField(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        controller: _nameController,
                        enabled: _isEditing,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name required' : null,
                      ),
                      _buildField(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      _buildField(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Phone required' : null,
                      ),
                      _buildField(
                        icon: Icons.badge_outlined,
                        label: 'Roll Number',
                        controller: _rollController,
                        enabled: false, // read-only always
                      ),
                      _buildField(
                        icon: Icons.school_outlined,
                        label: 'Department',
                        controller: _departmentController,
                        enabled: false,
                      ),
                      _buildField(
                        icon: Icons.layers_outlined,
                        label: 'Semester',
                        controller: _semesterController,
                        enabled: false,
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4A90FF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF4A90FF),
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: enabled
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Colors.white, width: 1.5),
              ),
              errorStyle: const TextStyle(color: Colors.yellow),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}