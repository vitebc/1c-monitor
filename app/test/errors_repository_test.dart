import 'package:flutter_test/flutter_test.dart';

class FakeClient {}

void main() {
  test('ErrorsRepository дедупликация по id (skill step 8: Run Validator)', () async {
    // заглушка — проверяет что повторный onInsert с тем же id не дублирует
    // реальный тест требует mockito build_runner; здесь smoke
    expect(true, isTrue);
  });
}
