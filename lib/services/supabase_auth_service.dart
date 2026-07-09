import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/auth_session.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  @override
  Future<AuthSession?> restoreSession() async {
    final session = _client.auth.currentSession;
    return _toSession(session);
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final session = _toSession(response.session);
    if (session == null) {
      throw const AuthException('Sign-in completed but no session was returned.');
    }

    return session;
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final session = _toSession(response.session);
    if (session == null) {
      throw const AuthException(
        'Account created. Check your email to confirm the account, then sign in.',
      );
    }

    return session;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AuthSession? _toSession(supabase.Session? session) {
    if (session == null || session.user.email == null) {
      return null;
    }

    return AuthSession(
      email: session.user.email!.trim().toLowerCase(),
      signedInAt: DateTime.now(),
    );
  }
}