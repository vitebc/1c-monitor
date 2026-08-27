import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_1c/data/models/error_api_model.dart';
import 'package:monitor_1c/data/repositories/errors_repository.dart';
import 'package:monitor_1c/data/services/supabase_service.dart';
import 'package:monitor_1c/ui/features/errors/view_models/errors_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends SupabaseClient {
  FakeSupabaseClient() : super('http://localhost:54321', 'fake');
}

class FakeSupabaseService extends SupabaseService {
  FakeSupabaseService() : super(FakeSupabaseClient());
  @override
  Future<List<ErrorApiModel>> fetchErrors({required String base, int limit = 50, String? level}) async => [];
  @override
  RealtimeChannel subscribeErrors({required String base, required void Function(ErrorApiModel) onInsert}) {
    // возвращаем фейковый канал — не подписываемся
    return FakeSupabaseClient().channel('fake');
  }

  @override
  Future<void> markRead(String id) async {}
  @override
  SupabaseClient get client => FakeSupabaseClient();
}

void main() {
  test('ErrorsViewModel load empty', () async {
    final repo = ErrorsRepository(service: FakeSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    expect(vm.errors, isEmpty);
    await vm.load();
    expect(vm.isLoading, isFalse);
    expect(vm.errors, isEmpty);
    expect(vm.errorMsg, isNull);
  });

  test('ErrorsViewModel setBase triggers reload', () async {
    final repo = ErrorsRepository(service: FakeSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    await vm.setBase('TEST_BASE');
    expect(vm.selectedBase, equals('TEST_BASE'));
  });

  test('ErrorsViewModel unreadCount', () async {
    final repo = ErrorsRepository(service: FakeSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    expect(vm.unreadCount, equals(0));
  });
}
