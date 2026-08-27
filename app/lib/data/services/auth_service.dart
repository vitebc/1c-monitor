import 'package:supabase_flutter/supabase_flutter.dart';

/// Step 2: Service — stateless обёртка над Supabase Auth (skill)
class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async => await _client.auth.signOut();

  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }
}
