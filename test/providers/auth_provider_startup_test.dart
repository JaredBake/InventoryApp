import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/auth_session.dart';
import 'package:inventory_app/providers/auth_provider.dart';
import 'package:inventory_app/services/auth_service.dart';

class _FakeAuthService implements AuthService {
  int restoreSessionCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreSessionCalls += 1;
    return AuthSession(
      userId: 'persisted-user',
      email: 'persisted@example.com',
      signedInAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      userId: 'signed-in-user',
      email: email,
      signedInAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      userId: 'signed-up-user',
      email: email,
      signedInAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

Future<void> _waitForLoadingComplete(AuthProvider provider) async {
  for (var i = 0; i < 100; i++) {
    if (!provider.isLoading) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('AuthProvider did not finish startup loading in time.');
}

void main() {
  group('AuthProvider startup', () {
    test('starts signed out and clears persisted session on launch', () async {
      final service = _FakeAuthService();
      final provider = AuthProvider(service: service);

      await _waitForLoadingComplete(provider);

      expect(service.signOutCalls, 1);
      expect(service.restoreSessionCalls, 0);
      expect(provider.session, isNull);
      expect(provider.isSignedIn, isFalse);
      expect(provider.error, isNull);
    });
  });
}