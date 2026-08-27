import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_1c/data/repositories/auth_repository.dart';
import 'package:monitor_1c/data/services/auth_service.dart';
import 'package:monitor_1c/ui/features/auth/view_models/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthService extends AuthService {
  FakeAuthService() : super(FakeClient());
  bool shouldThrow = false;
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    if (shouldThrow) throw Exception('invalid');
    throw Exception('not implemented in fake');
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    throw Exception('not implemented');
  }
}

class FakeClient extends SupabaseClient {
  FakeClient() : super('http://localhost:54321', 'fake');
}

void main() {
  test('AuthViewModel initial state', () {
    final vm = AuthViewModel(repository: AuthRepository(service: FakeAuthService()));
    expect(vm.isAuthenticated, isFalse);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);
  });

  test('AuthViewModel signIn sets error on failure', () async {
    final svc = FakeAuthService()..shouldThrow = true;
    final repo = AuthRepository(service: svc);
    final vm = AuthViewModel(repository: repo);
    final ok = await vm.signIn('a@b.c', 'bad');
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
    expect(vm.isLoading, isFalse);
  });
}
