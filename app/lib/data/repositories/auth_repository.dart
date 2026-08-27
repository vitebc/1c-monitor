import '../../domain/models/app_user.dart';
import '../services/auth_service.dart';

/// Step 3: Repository — трансформирует AuthService модели в Domain (skill)
class AuthRepository {
  AuthRepository({required AuthService service}) : _service = service;
  final AuthService _service;

  AppUser? get currentUser {
    final u = _service.currentUser;
    if (u == null) return null;
    return AppUser(id: u.id, email: u.email ?? '', displayName: u.userMetadata?['display_name'] as String?);
  }

  Stream<AppUser?> get authStateChanges => _service.authStateChanges.map((s) {
        final u = s.session?.user;
        if (u == null) return null;
        return AppUser(id: u.id, email: u.email ?? '', displayName: u.userMetadata?['display_name'] as String?);
      });

  Future<AppUser> signIn(String email, String password) async {
    final res = await _service.signIn(email: email, password: password);
    final u = res.user;
    if (u == null) throw StateError('signIn: user is null');
    return AppUser(id: u.id, email: u.email ?? email);
  }

  Future<AppUser> signUp(String email, String password) async {
    final res = await _service.signUp(email: email, password: password);
    final u = res.user;
    if (u == null) throw StateError('signUp: user is null (проверь email confirmation)');
    return AppUser(id: u.id, email: u.email ?? email);
  }

  Future<void> signOut() => _service.signOut();
}
