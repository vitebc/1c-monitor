# Сборка 1c-monitor — Android / iOS / macOS / Windows

> Flutter 3.47 + Supabase + FCM. Один код — 4 платформы. Инструкция для Windows-хоста, но iOS/macOS собираются только на Mac.

## 0. Подготовка (один раз на новом компе)

### Общее
```powershell
# Flutter 3.47.2 stable
flutter --version  # Dart 3.13.1
flutter doctor -v

# Отключи телеметрию если не нужна
flutter --disable-analytics

# Включи Developer Mode на Windows (иначе симлинки не заведутся)
start ms-settings:developers  # Включить "Режим разработчика"
```

### Windows
- **Visual Studio 2022/Build Tools 2026** с `Desktop development with C++` (включает `MSVC`, `Windows 10/11 SDK`, `CMake`, `Ninja`)
- **Обязательно:** `C++ ATL для последних инструментов сборки v143 и v144 (x86 и x64)` — без него `flutter_local_notifications_windows` падает с `atlbase.h: No such file or directory`
- Проверка: `flutter doctor` → `[√] Visual Studio`
- Если `clang`/`ninja` не найден: `winget install Kitware.CMake; winget install Ninja-build.Ninja`

### Android
- **Android Studio** → при первом запуске поставь `Android SDK`, `Android SDK Command-line Tools`, `Android SDK Platform-Tools`
- Создай эмулятор: `AVD Manager` → `Pixel 8 API 34`
- Проверка: `flutter doctor` → `[√] Android toolchain`
- Если SDK в кастомном месте: `flutter config --android-sdk "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"`
- Принимай лицензии: `flutter doctor --android-licenses`

### iOS / macOS (только на Mac)
- **Xcode** из App Store (≥15) → `xcode-select --install`
- `sudo gem install cocoapods` → `pod --version`
- `open -a Xcode` → согласить лицензию
- Проверка: `flutter doctor` → `[√] Xcode`, `[√] CocoaPods`
- Apple Developer аккаунт для подписи (иначе только симулятор)

### Supabase
```powershell
npm i -g supabase  # 2.116+
supabase --version
docker --version   # нужен Docker Desktop (WSL2)
```

### Переменные окружения
Собери из `supabase status` после `supabase start`:
```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>
SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY> # только для watcher/curl, в app не нужен
```

В приложении прокидывай через `--dart-define` (не коммить в репу):
```powershell
flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>
```
Или создай `app/.env` / `dart_defines.json`:
```json
{"SUPABASE_URL":"http://127.0.0.1:54321","SUPABASE_ANON_KEY":"<PUBLISHABLE_KEY>"}
```
```powershell
flutter run --dart-define-from-file=dart_defines.json
```

---

## 1. Клонирование и зависимости

```powershell
git clone https://github.com/vitebc/1c-monitor.git
cd 1c-monitor
# если тестишь через ssh-туннель к серверу — держи туннель в отдельном окне:
# ssh -N -L 54321:127.0.0.1:54321 -L 54323:127.0.0.1:54323 user@SERVER

supabase start  # поднимет DB 54322 + Studio 54323 + API 54321 + seed.sql
supabase db lint  # No schema errors

cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # freezed + json_serializable
flutter analyze  # No issues found!
flutter test     # 8 passed
```

---

## 2. Windows (x64)

> Десктоп — самый быстрый способ проверить логику без эмулятора.

```powershell
cd app

# Debug (с hot-reload)
flutter run -d windows --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>

# Release (для раздачи)
flutter build windows --release --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>

# Артефакт: build\windows\x64\runner\Release\monitor_1c.exe (+ .dll)
# Упаковка в инсталлер (опционально): используй Inno Setup или `msix`:
flutter pub add msix  # один раз
flutter build windows --release
# или: dart run msix:create --install-certificate false
```

**Частые косяки:**
- `atlbase.h: No such file or directory` → поставь `C++ ATL для v143/v144` в Visual Studio Installer, перезагрузись
- `Building with plugins requires symlink support` → включи Developer Mode + перезапусти PowerShell
- `MSVC not found` → доустанови `Desktop development with C++` in Visual Studio Installer
- `supabase` не доступен на `127.0.0.1:54321` → проверь `supabase status` и туннель

---

## 3. Android (APK / AAB)

> Для Google Play нужен `AAB`, для ручной раздачи — `APK`.

### Подпись (один раз)

```powershell
# Сгенерируй keystore (запомни пароли!)
keytool -genkey -v -keystore D:\keys\1c-monitor.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Создай app\android\key.properties (не коммить!):
# storePassword=xxx
# keyPassword=xxx
# keyAlias=upload
# storeFile=D:\\keys\\1c-monitor.jks
```

`app\android\app\build.gradle` уже настроен на `key.properties` (если нет — добавь signingConfigs).

### Сборка

```powershell
cd app

# Debug на эмуляторе/телефоне
flutter run -d android --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Release APK (для теста на устройстве)
flutter build apk --release --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY> --dart-define=SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY>
# → build\app\outputs\flutter-apk\app-release.apk

# Release AAB (для Play Console)
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# → build\app\outputs\bundle\release\app-release.aab

# Проверка: установи APK на телефон
adb install build\app\outputs\flutter-apk\app-release.apk
```

**FCM на Android:** добавь `app\android\app\google-services.json` (из Firebase Console → Project Settings → Android). Без него пуши не придут, но Realtime-список работать будет.

---

## 4. iOS (только macOS)

> Нужен Mac + Xcode + Apple Developer (иначе только симулятор без подписи).

```bash
# На Mac:
cd app
flutter pub get
cd ios && pod install && cd ..

# Debug на симуляторе
open -a Simulator
flutter run -d ios --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>

# Release IPA (для TestFlight / App Store)
flutter build ipa --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --export-options-plist=ios/Runner/ExportOptions.plist
# → build/ios/ipa/monitor_1c.ipa

# Альтернатива: открыть Xcode и собрать архив
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

**FCM на iOS:** добавй `ios/Runner/GoogleService-Info.plist`, включи `Push Notifications` + `Background Modes → Remote notifications` в `Xcode → Signing & Capabilities`, загрузи `APNs Auth Key` в Firebase Console.

**Сборка iOS с Windows невозможна** — нужен Mac или `codemagic.io` / `GitHub Actions macos-latest`.

---

## 5. macOS (десктоп)

> Только на Mac, но собирается так же как Windows.

```bash
# На Mac:
cd app
flutter build macos --release --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=<PUBLISHABLE_KEY>
# → build/macos/Build/Products/Release/monitor_1c.app

# Подпись (если есть Apple Developer):
# Xcode → Runner → Signing & Capabilities → Team
# flutter build macos --release  # подпишет автоматом

# DMG (опционально):
# brew install create-dmg
# create-dmg build/macos/Build/Products/Release/monitor_1c.app
```

**Entitlements:** `macos/Runner/DebugProfile.entitlements` и `Release.entitlements` уже содержат `com.apple.security.network.client` + `network.server` — без них `Supabase auth` падает с `Operation not permitted` в sandbox. `Info.plist` содержит `NSAllowsArbitraryLoads` для `http://127.0.0.1`.

---

## 6. Web (опционально, для быстрой демо)

```powershell
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# → build\web\
# Залей на Firebase Hosting / Vercel / Supabase Hosting
```

---

## 7. Версионирование

`app/pubspec.yaml`:
```yaml
version: 0.1.0+1  # 0.1.0 — versionName/CFBundle, +1 — buildNumber/versionCode
```
Перед релизом bump'ай `+N` (Android `versionCode`, iOS `CFBundleVersion`).

---

## 8. Проверка после сборки

```bash
# Android: установи APK/AAB, залогинься, подпишись на DEMO, вставь ошибку:
curl -X POST https://xxx.supabase.co/rest/v1/errors -H "apikey: <SERVICE_ROLE_KEY>" -H "Authorization: Bearer <SERVICE_ROLE_KEY>" -H "Content-Type: application/json; charset=utf-8" -d '{"event_name":"ОшибкаПроведения","level":"Ошибка","metadata_object":"Документ.Заказ","data":{"doc_id":"РТ-0001"},"comment_text":"тест","base":"DEMO"}'
# → должна прилететь в список + пуш (если Firebase настроен)

# Windows/macOS: то же, но через Realtime — открой два окна приложения, в одном вставь ошибку, в другом должна появиться без pull-to-refresh
```

**Важно:** `anon` (`<PUBLISHABLE_KEY>`) не может INSERT — RLS режет `42501`. Используй `service_role` (`<SERVICE_ROLE_KEY>`) для вставки извне.

---

## 9. CI (автосборка)

`.github/workflows/ci.yml` уже настроен: `flutter analyze + test + supabase db lint + deno test` на каждый push в `main`. Для релизных артефактов добавь:

```yaml
- run: flutter build apk --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} ...
- run: flutter build windows --release ...
  # iOS/macOS — только на macos-latest раннере
```

Секреты в `GitHub → Settings → Secrets`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON`.

---

## 10. Чек-лист перед релизом

- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — 8 passed
- [ ] `supabase db lint` — No schema errors
- [ ] `dart_defines` указывают на прод `https://xxx.supabase.co`, не на `127.0.0.1`
- [ ] `google-services.json` (Android) и `GoogleService-Info.plist` (iOS) добавлены и не в `.gitignore`
- [ ] `keystore` / `ExportOptions.plist` не в репе, лежат в Secrets/CI
- [ ] `version` в `pubspec.yaml` bump'нут
- [ ] `supabase functions deploy watcher --no-verify-jwt` выполнен

Если что-то падает — смотри `flutter doctor -v` и логи `supabase status` / `supabase functions serve watcher --debug`.
