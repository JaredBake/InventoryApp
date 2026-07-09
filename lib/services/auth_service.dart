import '../models/auth_session.dart';

abstract class AuthService {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<AuthSession> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}