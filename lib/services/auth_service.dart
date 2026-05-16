// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Email/Password Sign In ──────────────────────────────────────────────
  Future<User> signIn({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    await _verifyRole(user.uid, selectedRole);
    return user;
  }

  // ─── Role Verification ───────────────────────────────────────────────────
  Future<void> _verifyRole(String uid, String selectedRole) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw Exception(
        'Account not found in database. Contact your administrator.',
      );
    }

    final storedRole = doc.data()!['role'] as String?;

    // ── Admins can log in from any role selection screen ──
    if (storedRole == 'admin') return;

    if (storedRole == null || storedRole != selectedRole) {
      await _auth.signOut();
      throw Exception(
        'Access denied. This account is registered as a '
            '${storedRole ?? "unknown"}, not a $selectedRole.',
      );
    }
  }

  // ─── Change Password ─────────────────────────────────────────────────────
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');
    await user.updatePassword(newPassword);
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Current User ────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
}