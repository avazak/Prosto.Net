# Инструкции по сборке и развертыванию Prosto.Net

## Требования для разработки

### Системные требования
- **Операционная система**: Windows 10+, macOS 10.14+, или Linux
- **RAM**: минимум 8 GB (рекомендуется 16 GB)
- **Свободное место**: минимум 10 GB

### Программное обеспечение
1. **Flutter SDK 3.8.1+**
   ```bash
   # Проверка версии
   flutter --version
   ```

2. **Android Studio** или **VS Code** с Flutter плагином

3. **Android SDK**
   - API Level 21+ (Android 5.0)
   - Build Tools 30.0.3+
   - Platform Tools

4. **Java Development Kit (JDK) 17**
   ```bash
   # Проверка версии
   java -version
   ```

## Настройка проекта

### 1. Клонирование и настройка
```bash
# Переход в директорию проекта
cd prosto_net

# Установка зависимостей
flutter pub get

# Проверка настройки Flutter
flutter doctor
```

### 2. Настройка Android
```bash
# Проверка подключенных устройств
flutter devices

# Включение режима разработчика на Android устройстве
# Настройки > О телефоне > Номер сборки (7 раз)
# Настройки > Для разработчиков > Отладка по USB
```

### 3. Размещение AAR файла
Убедитесь, что файл `tunnel-release.aar` находится в:
```
android/app/libs/tunnel-release.aar
```

## Сборка приложения

### Debug сборка (для разработки)
```bash
# Запуск на подключенном устройстве
flutter run

# Запуск с горячей перезагрузкой
flutter run --hot
```

### Release сборка (для распространения)
```bash
# Сборка APK
flutter build apk --release

# Сборка App Bundle (рекомендуется для Google Play)
flutter build appbundle --release

# Сборка с разделением по архитектурам
flutter build apk --split-per-abi --release
```

### Результаты сборки
- **APK файлы**: `build/app/outputs/flutter-apk/`
- **App Bundle**: `build/app/outputs/bundle/release/`

## Подписание APK (для релиза)

### 1. Создание ключа подписи
```bash
keytool -genkey -v -keystore ~/prosto-net-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias prosto-net
```

### 2. Настройка gradle
Создайте файл `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=prosto-net
storeFile=/path/to/prosto-net-key.jks
```

### 3. Обновление build.gradle
В `android/app/build.gradle.kts` добавьте конфигурацию подписи.

## Тестирование

### Запуск тестов
```bash
# Все тесты
flutter test

# Тесты с покрытием
flutter test --coverage

# Интеграционные тесты
flutter drive --target=test_driver/app.dart
```

### Анализ кода
```bash
# Статический анализ
flutter analyze

# Форматирование кода
flutter format .
```

## Развертывание

### Google Play Store
1. Создайте аккаунт разработчика Google Play
2. Загрузите App Bundle файл
3. Заполните метаданные приложения
4. Настройте тестирование
5. Опубликуйте приложение

### Альтернативные способы распространения
- **APK файлы** - прямая установка
- **Firebase App Distribution** - для тестирования
- **Amazon Appstore** - альтернативный магазин

## Отладка

### Общие проблемы

#### 1. Ошибки сборки Gradle
```bash
# Очистка кэша
flutter clean
flutter pub get

# Пересборка
flutter build apk --release
```

#### 2. Проблемы с AAR библиотекой
- Проверьте путь к файлу `tunnel-release.aar`
- Убедитесь в совместимости версий Java
- Проверьте настройки в `build.gradle.kts`

#### 3. Ошибки разрешений
- Проверьте `AndroidManifest.xml`
- Убедитесь в правильности запроса разрешений в коде

### Логирование
```bash
# Просмотр логов Android
flutter logs

# Логи через ADB
adb logcat | grep flutter
```

## Оптимизация

### Размер APK
```bash
# Анализ размера
flutter build apk --analyze-size

# Включение ProGuard/R8
# В android/app/build.gradle.kts:
# buildTypes {
#     release {
#         minifyEnabled = true
#         proguardFiles(...)
#     }
# }
```

### Производительность
- Используйте `flutter build apk --release` для финальной сборки
- Оптимизируйте изображения и ресурсы
- Минимизируйте количество зависимостей

## Мониторинг

### Crashlytics (рекомендуется)
```yaml
# В pubspec.yaml
dependencies:
  firebase_crashlytics: ^3.4.8
```

### Analytics
```yaml
# В pubspec.yaml
dependencies:
  firebase_analytics: ^10.7.4
```

## Обновления

### Автоматические обновления
- Настройте CI/CD pipeline
- Используйте GitHub Actions или GitLab CI
- Автоматизируйте тестирование и сборку

### Версионирование
```yaml
# В pubspec.yaml
version: 1.0.0+1
# Формат: major.minor.patch+build
```

## Поддержка

### Документация
- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Developer Guide](https://developer.android.com/)

### Сообщество
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

## Контрольный список релиза

- [ ] Все тесты проходят успешно
- [ ] Код проанализирован и отформатирован
- [ ] APK подписан релизным ключом
- [ ] Протестировано на различных устройствах
- [ ] Обновлена документация
- [ ] Настроен мониторинг ошибок
- [ ] Подготовлены материалы для магазина приложений

