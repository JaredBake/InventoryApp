import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthSession? _session;
  bool _loading = true;
  String? _error;

  AuthProvider({required AuthService service}) : _service = service {
    _restoreSession();
  }

  AuthSession? get session => _session;
  bool get isLoading => _loading;
  bool get isSignedIn => _session != null;
  String? get error => _error;

  Future<void> _restoreSession() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _service.restoreSession();
    } catch (error) {
      _error = error.toString();
      _session = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _error = null;
    notifyListeners();

    try {
      _session = await _service.signIn(email: email, password: password);
    } on AuthException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = error.toString();
    }

    notifyListeners();
  }

  Future<void> signUp({required String email, required String password}) async {
    _error = null;
    notifyListeners();

    try {
      _session = await _service.signUp(email: email, password: password);
    } on AuthException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = error.toString();
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await _service.signOut();
    _session = null;
    _error = null;
    notifyListeners();
  }
}