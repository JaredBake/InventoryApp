import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  static const _accountsKey = 'inventory_app.auth.accounts.v1';
  static const _sessionKey = 'inventory_app.auth.session.v1';

  @override
  Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = await _readAccounts();
    final storedPassword = accounts[normalizedEmail];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('Invalid email or password.');
    }

    return _writeSession(normalizedEmail);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = await _readAccounts();
    if (accounts.containsKey(normalizedEmail)) {
      throw const AuthException('An account already exists for that email.');
    }
    accounts[normalizedEmail] = password;
    await _writeAccounts(accounts);
    return _writeSession(normalizedEmail);
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<Map<String, String>> _readAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      await prefs.remove(_accountsKey);
      return <String, String>{};
    }
  }

  Future<void> _writeAccounts(Map<String, String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<AuthSession> _writeSession(String email) async {
    final session = AuthSession(
      userId: email,
      email: email,
      signedInAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}