// lib/screens/student/student_help_support_screen.dart

import 'package:flutter/material.dart';

class StudentHelpSupportScreen extends StatefulWidget {
  const StudentHelpSupportScreen({super.key});

  @override
  State<StudentHelpSupportScreen> createState() =>
      _StudentHelpSupportScreenState();
}

class _StudentHelpSupportScreenState extends State<StudentHelpSupportScreen> {
  // ── Tab state ─────────────────────────────────────────────
  int _selectedTab = 0; // 0 = FAQs, 1 = Contact Us

  // ── FAQ state ─────────────────────────────────────────────
  int? _expandedIndex;

  // ── Contact form state ────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I download study materials?',
      'answer':
      'Go to the Materials tab, select your department and semester, then tap the download icon next to any file. Downloads appear in the Your Downloads section on the Home screen.',
    },
    {
      'question': 'I cannot log in to my account. What should I do?',
      'answer':
      'Tap "Forgot Password" on the login screen. Enter your university email and check your inbox for a reset link. If you still cannot log in, contact support.',
    },
    {
      'question': 'How do I search for a book in the library?',
      'answer':
      'Open the Library tab and use the search bar at the top. You can filter by title, author, or subject. Tap a book to view its details and availability.',
    },
    {
      'question': 'Why is a file not downloading?',
      'answer':
      'Check your internet connection first. If the issue persists, try clearing the app cache from your phone settings or re-installing the app. Large files may take a few minutes on slow connections.',
    },
    {
      'question': 'Can I access materials offline?',
      'answer':
      'Yes. Once a file is downloaded it is stored locally and can be opened without internet. Look for the downloaded files under Your Downloads on the Home screen.',
    },
    {
      'question': 'How do I report a wrong or missing file?',
      'answer':
      'Use the Contact Us tab on this screen to send us a message. Mention the file name, subject, and semester so we can fix it quickly.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    // Simulate sending to backend
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with real API call, e.g.:
    // await SupportRepository.sendMessage(
    //   subject: _subjectController.text,
    //   message: _messageController.text,
    // );

    setState(() {
      _isSending = false;
      _sent = true;
    });

    _subjectController.clear();
    _messageController.clear();
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
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // ── Tab switcher ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTab('FAQs', 0),
                            _buildTab('Contact Us', 1),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tab content ───────────────────────────
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildFaqList()
                          : _buildContactForm(),
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTab = index;
          _sent = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF4A90FF)
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FAQ List ────────────────────────────────────────────────
  Widget _buildFaqList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _faqs.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Colors.white24,
      ),
      itemBuilder: (context, index) {
        final isExpanded = _expandedIndex == index;
        return GestureDetector(
          onTap: () => setState(
                  () => _expandedIndex = isExpanded ? null : index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _faqs[index]['question']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Text(
                      _faqs[index]['answer']!,
                      style: const TextStyle(
                        fontSize: 14,

                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Contact Form ────────────────────────────────────────────
  Widget _buildContactForm() {
    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Message Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our support team will get back to you within 24 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,

                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => setState(() => _sent = false),
                child: const Text(
                  'Send another message',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'re here to help. Send us a message and we\'ll respond as soon as possible.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Subject field
            _buildFormLabel('Subject'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Please enter a subject' : null,
              decoration: _inputDecoration('e.g. Cannot download a file'),
            ),

            const SizedBox(height: 20),

            // Message field
            _buildFormLabel('Message'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe your issue';
                }
                if (v.trim().length < 20) {
                  return 'Message is too short (min 20 characters)';
                }
                return null;
              },
              decoration: _inputDecoration(
                'Describe your issue in detail...',
                alignTop: true,
              ),
            ),

            const SizedBox(height: 12),

            // Character hint
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (_, value, __) {
                return Text(
                  '${value.text.length} characters',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4A90FF),
                  ),
                )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(_isSending ? 'Sending...' : 'Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A90FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Direct email hint
            Center(
              child: Text(
                'Or email us directly at support@studysharez.com',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool alignTop = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: alignTop ? 16 : 14,
      ),
      alignLabelWithHint: alignTop,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.yellow, fontSize: 12),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.yellowAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.yellowAccent, width: 1.5),
      ),
    );
  }
}