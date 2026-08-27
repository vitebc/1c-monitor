# app — Flutter клиент 1c-monitor

Архитектура: `flutter-apply-architecture-best-practices` (MVVM + Repository).

```
lib/
├── data/
│   ├── models/error_api_model.dart      # сырая модель из Supabase
│   ├── services/supabase_service.dart   # обёртка над Supabase client
│   └── repositories/errors_repository.dart
├── domain/
│   ├── models/error.dart                # чистая модель (freezed)
│   └── use_cases/                       # опционально (фильтры, группировка)
└── ui/
    ├── core/                            # тема, виджеты
    └── features/errors/
        ├── view_models/errors_view_model.dart  # ChangeNotifier
        └── views/errors_view.dart
core/
├── notifications/  # FCM + local_notifications
└── supabase/       # init
```

## Запуск
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d android|ios|macos|windows
```

Сначала `supabase start` и `supabase db push` (см. ../AGENTS.md).
