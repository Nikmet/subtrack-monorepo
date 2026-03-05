# SubTrack Mobile

Flutter приложение в monorepo `subtrack/mobile`.

## Требования

- Flutter SDK 3.22+
- Dart SDK 3.3+

## Быстрый старт

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://subtrack-server.vercel.app
```

## Конфигурация

`API_BASE_URL` можно переопределить через `--dart-define`.

Локальный эндпоинт API:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

## Тесты

```bash
flutter test
flutter test integration_test
```

## OpenAPI

Схема OpenAPI находится в `openapi/openapi.json`.
Generated слой располагается в `lib/api/generated/`.
