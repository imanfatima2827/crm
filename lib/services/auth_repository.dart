import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/profile.dart';

class AuthRepository {
  Session? get currentSession => sb.auth.currentSession;
  User? get currentUser => sb.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => sb.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    await sb.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() async => sb.auth.signOut();

  Future<void> resetPassword(String email) async {
    await sb.auth.resetPasswordForEmail(email);
  }

  /// Fetches the signed-in user's profile, joined with role info.
  Future<Profile?> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await sb
        .from(Tables.profiles)
        .select('*, role:roles(*)')
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }
}
