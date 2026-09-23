import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  StreamSubscription<AuthState>? _sub;

  AuthStatus status = AuthStatus.unknown;
  Profile? profile;
  String? error;
  bool loadingProfile = false;

  AuthProvider() {
    _sub = _repo.onAuthStateChange.listen((event) async {
      if (event.session == null) {
        status = AuthStatus.signedOut;
        profile = null;
        notifyListeners();
      } else {
        status = AuthStatus.signedIn;
        notifyListeners();
        await _loadProfile();
      }
    });
    if (_repo.currentSession != null) {
      status = AuthStatus.signedIn;
      _loadProfile();
    } else {
      status = AuthStatus.signedOut;
    }
  }

  Future<void> _loadProfile() async {
    loadingProfile = true;
    notifyListeners();
    try {
      profile = await _repo.fetchMyProfile();
    } catch (_) {
      profile = null;
    }
    loadingProfile = false;
    notifyListeners();
  }

  Future<void> refreshProfile() => _loadProfile();

  Future<String?> signIn(String email, String password) async {
    try {
      error = null;
      await _repo.signIn(email, password);
      return null;
    } on AuthException catch (e) {
      error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String fullName) async {
    try {
      error = null;
      await _repo.signUp(email, password, fullName);
      return null;
    } on AuthException catch (e) {
      error = e.message;
      notifyListeners();
      return e.message;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> signOut() => _repo.signOut();

  bool get isAdmin => profile?.isAdmin ?? false;
  bool get isManager => profile?.isManager ?? false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
