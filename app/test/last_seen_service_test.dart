import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitor_1c/core/cache/last_seen_service.dart';

void main() {
  test('LastSeenService set/get per base', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = await LastSeenService.create();
    expect(svc.getLastSeenId('DEMO'), isNull);
    await svc.setLastSeenId('DEMO', 'uuid-123');
    expect(svc.getLastSeenId('DEMO'), equals('uuid-123'));
    expect(svc.getLastSeenId('OTHER'), isNull);
    await svc.clearBase('DEMO');
    expect(svc.getLastSeenId('DEMO'), isNull);
  });

  test('LastSeenService getUnreadCount', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = await LastSeenService.create();
    expect(svc.getUnreadCount(['3','2','1'], null), equals(3));
    expect(svc.getUnreadCount(['3','2','1'], '2'), equals(1)); // только '3' новее '2'
    expect(svc.getUnreadCount(['3','2','1'], '3'), equals(0));
    expect(svc.getUnreadCount(['3','2','1'], 'unknown'), equals(3));
  });
}
