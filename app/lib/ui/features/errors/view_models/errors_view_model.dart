import 'package:flutter/foundation.dart';
import '../../../../data/repositories/errors_repository.dart';
import '../../../../domain/models/error.dart';

/// ViewModel — управляет UI-состоянием, инжектит Repository (skill: UI Layer).
/// Хранит immutable снапшот для View, уведомляет через ChangeNotifier.
class ErrorsViewModel extends ChangeNotifier {
  ErrorsViewModel({required ErrorsRepository repository}) : _repo = repository;

  final ErrorsRepository _repo;

  List<ErrorEntry> _errors = [];
  List<ErrorEntry> get errors => List.unmodifiable(_errors);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  String _selectedBase = 'DEMO';
  String get selectedBase => _selectedBase;

  String? _levelFilter; // null = все
  String? get levelFilter => _levelFilter;

  void Function()? _unsubscribe;

  Future<void> load() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();
    try {
      _errors = await _repo.getErrors(base: _selectedBase, level: _levelFilter);
    } catch (e) {
      _errorMsg = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBase(String base) async {
    if (base == _selectedBase) return;
    _selectedBase = base;
    await _unsubscribe?.call();
    _unsubscribe = null;
    await load();
    await subscribeRealtime();
  }

  void setLevelFilter(String? level) {
    _levelFilter = level;
    load();
  }

  Future<void> subscribeRealtime() async {
    await _unsubscribe?.call();
    _unsubscribe = await _repo.subscribe(_selectedBase, (entry) {
      // вставка в начало (новые сверху), дедупликация уже в repo
      _errors = [entry, ..._errors];
      notifyListeners();
    });
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    _errors = _errors.map((e) => e.id == id ? e.copyWith(isRead: true) : e).toList();
    notifyListeners();
  }

  int get unreadCount => _errors.where((e) => !e.isRead).length;

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }
}
