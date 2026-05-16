// lib/screens/auth/forgot_password_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ─── Validator ────────────────────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  // ─── Send Reset Email ─────────────────────────────────────────────────────
  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('>>> Sending reset email to: ${_emailController.text.trim()}');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      debugPrint('>>> sendPasswordResetEmail completed without error');

      if (!mounted) return;

      await _controller.reverse();
      setState(() => _emailSent = true);
      _controller.forward();
    } on FirebaseAuthException catch (e) {
      debugPrint('>>> FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      switch (e.code) {
        case 'user-not-found':
          _showError('No account found with this email address.');
          break;
        case 'invalid-email':
          _showError('Please enter a valid email address.');
          break;
        case 'too-many-requests':
          _showError('Too many attempts. Please try again later.');
          break;
        default:
          _showError('Error: ${e.code} — ${e.message}');
      }
    } catch (e) {
      debugPrint('>>> Unexpected error: $e');
      if (!mounted) return;
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Resend Email ─────────────────────────────────────────────────────────
  Future<void> _handleResend() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('>>> Resending reset email to: ${_emailController.text.trim()}');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      debugPrint('>>> Resend completed without error');

      if (!mounted) return;
      _showSuccess('Reset email sent again!');
    } on FirebaseAuthException catch (e) {
      debugPrint('>>> Resend FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (!mounted) return;
      if (e.code == 'too-many-requests') {
        _showError('Too many attempts. Please wait a moment and try again.');
      } else {
        _showError('Failed to resend. Error: ${e.code}');
      }
    } catch (e) {
      debugPrint('>>> Resend unexpected error: $e');
      if (!mounted) return;
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () {
            if (_emailSent) {
              _controller.reverse().then((_) {
                setState(() => _emailSent = false);
                _controller.forward();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: _emailSent ? _buildSuccessStep() : _buildEmailStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Enter Email ──────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.06),

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4A90FF), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.lock_reset_outlined,
                  size: 50, color: Color(0xFF4A90FF)),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Enter your registered email address and\nwe\'ll send you a password reset link.',
            textAlign: TextAlign.center,
            style:
            TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),

          const SizedBox(height: 40),

          // Email Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF4A90FF), width: 2),
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Email address',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(Icons.mail_outline,
                      color: Colors.grey[700], size: 24),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Send Reset Link Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                disabledBackgroundColor:
                const Color(0xFF4A90FF).withOpacity(0.6),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
                  : const Text(
                'Send Reset Link',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const Spacer(),

          // Back to Login
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Remember your password? ',
                    style:
                    TextStyle(color: Colors.grey[600], fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: Color(0xFF4A90FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Email Sent Success ───────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.08),

        // Success Icon
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_outlined,
                size: 56, color: Colors.green),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to',
          textAlign: TextAlign.center,
          style:
          TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),

        const SizedBox(height: 4),

        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Click the link in the email to reset your password.\nCheck your spam folder if you don\'t see it.',
          textAlign: TextAlign.center,
          style:
          TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6),
        ),

        const SizedBox(height: 48),

        // Back to Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive the email? ",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            GestureDetector(
              onTap: _isLoading ? null : _handleResend,
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF4A90FF)),
              )
                  : const Text(
                'Resend',
                style: TextStyle(
                  color: Color(0xFF4A90FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const Spacer(),
      ],
    );
  }
}