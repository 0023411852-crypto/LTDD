# Daily News & Weather Portal — Đề tài 5

Ứng dụng Flutter đọc tin tức tổng hợp (RSS báo Việt Nam) + thời tiết (Open-Meteo).

## Đã có trong bản này (Bước 1)
- Màn hình **Home**: Weather Card + Chips chuyên mục + Danh sách tin mới, Pull-to-refresh, đủ 4 trạng thái loading / data / empty / error
- **Chi tiết bài báo**: WebView đọc bài gốc + nút Bookmark (UI, lưu thật bằng Hive ở bước sau)
- **Chi tiết thời tiết**: hiện tại + dự báo 7 ngày, chọn thành phố mẫu trong code
- Models: `Article`, `Weather` — Services: `NewsService` (RSS VnExpress / Tuổi Trẻ / Thanh Niên), `WeatherService` (Open-Meteo, không cần API key)
- Dark Mode theo hệ thống (Material 3)

## Cách chạy trên máy của bạn

> Lưu ý: Thư mục này chứa phần `lib/` + `pubspec.yaml` do Muse tạo sẵn.
> Bạn tạo khung Android/iOS bằng lệnh ở bước 1, rồi ghi đè `lib/` và `pubspec.yaml` bằng file trong thư mục này.

```bash
# 1. Cài Flutter: https://docs.flutter.dev/get-started/install  (kiểm tra: flutter doctor)
# 2. Tạo khung project (tên phải đúng để khớp package)
flutter create daily_news_weather_portal
# 3. Copy lib/, pubspec.yaml, analysis_options.yaml, test/ trong thư mục này đè vào project vừa tạo
# 4. Lấy package + chạy
cd daily_news_weather_portal
flutter pub get
flutter run
```

Cần quyền Internet (đã có mặc định khi flutter create ở chế độ debug).
Khi chạy release trên Android, kiểm tra `android/app/src/main/AndroidManifest.xml` có:
`<uses-permission android:name="android.permission.INTERNET"/>`

## Cấu trúc
```
lib/
  main.dart
  models/article.dart, weather.dart
  services/news_service.dart, weather_service.dart
  screens/home_screen.dart, article_detail_screen.dart, weather_detail_screen.dart
  widgets/weather_card.dart, news_card.dart
```

## Bước tiếp theo (theo lộ trình)
1. Tìm kiếm tin theo từ khóa
2. Lưu Bookmark thật bằng Hive + màn hình Đã lưu / đọc offline
3. GPS thật (geolocator) + tìm thành phố cho thời tiết
4. Build APK nộp bài: `flutter build apk --release`
