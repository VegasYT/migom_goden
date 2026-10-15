# courier_app

A new Flutter project.

## Сборка

По умолчанию приложение работает с API на сервере `https://migom.site/api/v1`, WebSocket - `wss://migom.site/ws`. Другой адрес задаётся при сборке:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2/api/v1    # локальный стек из эмулятора Android
flutter build apk --release                                   # для сервера, адрес по умолчанию
```

Ключ Яндекс MapKit в репозиторий не входит. Его задают в `android/local.properties` (файл не коммитится):

```properties
mapkit.apiKey=<ключ MapKit>
```

или переменной окружения `MAPKIT_API_KEY` при сборке. Без ключа приложение собирается, но карта не грузится.

Android-сборке нужен JDK 21: библиотека MapKit (`maps.mobile` 4.22) собрана под Java 21, с JDK 17 сборка падает с "class file has wrong version 65.0, should be 61.0". Выбрать JDK для Flutter: `flutter config --jdk-dir="<путь к JDK 21>"`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
