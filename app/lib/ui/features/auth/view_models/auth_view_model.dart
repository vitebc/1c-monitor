import 'package:flutter/foundation.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/app_user.dart';

/// Step 5: ViewModel (skill) — инжектит Repository, хранит immutable state
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository repository}) : _repo = repository {
    // слушаем изменения сессии
    _repo.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
    });
    _user = _repo.currentUser;
  }

  final AuthRepository _repo;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repo.signIn(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repo.signUp(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    notifyListeners();
  }
}
