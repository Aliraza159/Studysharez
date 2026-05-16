// lib/screens/teacher/help_support_screen.dart

import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I reset my password?',
      'answer':
      'Go to the login screen and tap "Forgot Password". Enter your registered email and follow the instructions sent to your inbox.',
    },
    {
      'question': 'How do I add a new class?',
      'answer':
      'From the home screen tap the "+" button and select "New Class". Fill in the class details and tap Save.',
    },
    {
      'question': 'How do I contact a student\'s parent?',
      'answer':
      'Open the student\'s profile and tap the "Contact" button. You can send a message or find the parent\'s phone number there.',
    },
    {
      'question': 'Can I export attendance records?',
      'answer':
      'Yes. Go to Attendance, select the date range, and tap the export icon in the top right corner to download as a PDF or CSV.',
    },
    {
      'question': 'Who do I contact for technical issues?',
      'answer':
      'Reach us at support@eduapp.com or call +1 800 000 1234 on weekdays between 9 AM – 6 PM.',
    },
  ];

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
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // FAQ List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90FF),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _faqs.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white24,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    final isExpanded = _expandedIndex == index;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      faq['question']!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Text(
                                    faq['answer']!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}