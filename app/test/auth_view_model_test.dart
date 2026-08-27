import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_1c/ui/features/auth/view_models/auth_view_model.dart';
import 'package:monitor_1c/data/repositories/auth_repository.dart';
import 'package:monitor_1c/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mockito/mockito.dart';

// smoke: ViewModel стартует неавторизованным, переключает isLoading
class MockAuthService extends Mock implements AuthService {
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

void main() {
  test('AuthViewModel initial state', () {
    final vm = AuthViewModel(repository: AuthRepository(service: MockAuthService()));
    expect(vm.isAuthenticated, isFalse);
    expect(vm.isLoading, isFalse);
    expect(vm.error, isNull);
  });

  test('AuthViewModel signIn sets error on failure', () async {
    final svc = MockAuthService();
    // authService.signIn будет брошен — мокаем через when
    when(svc.signIn(email: anyNamed('email'), password: anyNamed('password')))
        .thenThrow(Exception('invalid'));
    final repo = AuthRepository(service: svc);
    final vm = AuthViewModel(repository: repo);
    final ok = await vm.signIn('a@b.c', 'bad');
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
    expect(vm.isLoading, isFalse);
  });
}
