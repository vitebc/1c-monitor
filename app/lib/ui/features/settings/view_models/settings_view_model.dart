import 'package:flutter/foundation.dart';
import '../../../../data/repositories/settings_repository.dart';

/// ViewModel для экрана настроек/подписок на Базы
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository repository}) : _repo = repository;

  final SettingsRepository _repo;

  List<String> _bases = [];
  List<String> get bases => List.unmodifiable(_bases);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bases = await _repo.getMyBases();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBase(String base) async {
    if (base.trim().isEmpty) return false;
    if (_bases.contains(base.trim())) return false;
    try {
      await _repo.addBase(base.trim());
      _bases = [..._bases, base.trim()];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> removeBase(String base) async {
    try {
      await _repo.removeBase(base);
      _bases = _bases.where((b) => b != base).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
