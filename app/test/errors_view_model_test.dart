import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_1c/data/repositories/errors_repository.dart';
import 'package:monitor_1c/data/services/supabase_service.dart';
import 'package:monitor_1c/domain/models/error.dart';
import 'package:monitor_1c/ui/features/errors/view_models/errors_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mockito/mockito.dart';

class MockSupabaseService extends Mock implements SupabaseService {
  @override
  Future<List<dynamic>> fetchErrors({required String base, int limit = 50, String? level}) async => [];
  @override
  RealtimeChannel subscribeErrors({required String base, required void Function(dynamic) onInsert}) => MockRealtimeChannel();
  @override
  Future<void> markRead(String id) async {}
  @override
  SupabaseClient get client => MockSupabaseClient();
}

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  test('ErrorsViewModel load empty', () async {
    final repo = ErrorsRepository(service: MockSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    expect(vm.errors, isEmpty);
    await vm.load();
    expect(vm.isLoading, isFalse);
    expect(vm.errors, isEmpty);
    expect(vm.errorMsg, isNull);
  });

  test('ErrorsViewModel setBase triggers reload', () async {
    final repo = ErrorsRepository(service: MockSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    await vm.setBase('TEST_BASE');
    expect(vm.selectedBase, equals('TEST_BASE'));
  });

  test('ErrorsViewModel unreadCount', () async {
    // через приватный кэш нельзя — проверяем логику через публичный getter после mock
    final repo = ErrorsRepository(service: MockSupabaseService());
    final vm = ErrorsViewModel(repository: repo);
    expect(vm.unreadCount, equals(0));
  });
}
