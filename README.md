# 📱 Daily News & Weather Portal

[![Release](https://img.shields.io/badge/Release-v1.4.0-blue.svg)](https://github.com/0023411852-crypto/LTDD/releases/tag/v1.4.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2.svg?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg?logo=android)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

> **Đề tài 5:** Ứng dụng đọc tin tức tổng hợp thời gian thực kết hợp dự báo thời tiết thông minh & phân quyền quản trị cao cấp.

---

## 🌟 Điểm nổi bật phiên bản v1.1.0 (Highlights)

- 🎨 **Giao diện hiện đại & mượt mà (Modern Fluid UI)**: Thiết kế Material 3 cao cấp, hiệu ứng Breathing Glow Animation trên logo chào mừng, hỗ trợ Dark Mode / Light Mode thích ứng.
- 📰 **Tin tức đa nguồn chuẩn xác**: Tự động bóc tách tin tức từ các báo điện tử hàng đầu Việt Nam (VnExpress, Tuổi Trẻ, Thanh Niên...) với WebView đọc bài trực tiếp.
- 🌤️ **Dự báo thời tiết thời gian thực**: Tích hợp Open-Meteo API và định vị GPS thực tế, dự báo chi tiết theo giờ và 7 ngày tới cho 63 tỉnh/thành phố tại Việt Nam.
- ❤️ **Quản lý địa điểm yêu thích (Không Mock Data)**: Lưu trữ các thành phố quan tâm trực tiếp vào bộ nhớ máy, cập nhật trạng thái thời tiết sống động.
- 🛡️ **Bảng điều khiển Quản trị viên (Admin Panel)**: Bổ sung nguồn RSS tùy chỉnh, kiểm tra tính hợp lệ HTTPS, duyệt/ẩn bài viết và xóa bài viết vào Blacklist vĩnh viễn.
- 🔔 **Hệ thống thông báo phân luồng**: Tách biệt giữa Tin nóng phá cách (Breaking News) và Bản tin thời tiết buổi sáng lúc 07:00.

---

## ⚡ Hệ thống cảnh báo thông minh & Tối ưu trải nghiệm (Smart Alerts & UX)

- 🚨 **Tự động nhận diện Tin nóng & Khẩn cấp (`BreakingNewsDetectorService`)**:
  - Tự động phân tích các bài báo RSS từ VnExpress, Tuổi Trẻ, Thanh Niên... bằng bộ từ khóa thiên tai, bão lũ, hỏa hoạn, động đất, sự cố nghiêm trọng.
  - Tự động gắn huy hiệu **`🔴 TIN NÓNG`** nổi bật trên Slider tiêu điểm và danh sách dòng sự kiện.
- ⛈️ **Cảnh báo thời tiết nguy hiểm thời gian thực**: Tự động nhận diện thời tiết xấu (dông sét WMO 95/96/99, gió giật mạnh, mưa lớn ngập lụt) tại vị trí người dùng và gửi cảnh báo an toàn.
- 🔕 **Chiến lược thông báo không làm phiền (Anti-Spam & Anti-Fatigue)**:
  - Chỉ gửi thông báo đẩy (Banner nổi & Tab Chuông) khi có tin thật sự khẩn cấp hoặc thời tiết xấu; các tin thường nhật để người dùng chủ động mở app khi rảnh rỗi.
  - Cơ chế ghi nhớ lịch sử qua `SharedPreferences`, chống lặp chuông khi vuốt làm mới trang; tôn trọng hoàn toàn công tắc bật/tắt trong Cài đặt.
- 🚪 **Trải nghiệm mở app & điều hướng đăng nhập tinh gọn**:
  - Tự động ghi nhớ trạng thái bỏ qua: lần mở app sau vào thẳng Trang chủ, chỉ mở màn hình Đăng nhập khi người dùng chủ động yêu cầu từ trang Cá nhân.
  - Giao diện Đăng nhập / Đăng ký chuẩn mực: loại bỏ nút "Bỏ qua" dư thừa, sử dụng nút mũi tên quay lại mượt mà tích hợp `PopScope`.
- 🛠️ **Quản trị nguồn tin & Thời hạn lưu trữ bài viết độc lập (Admin Controls)**:
  - Cho phép Admin điều chỉnh **số lượng bài tối đa** (15, 30, 50, 100 tin hoặc không giới hạn) và **thời gian lưu trữ** (1, 3, 7, 14, 30 ngày hoặc vĩnh viễn) cho từng nguồn RSS riêng biệt.
  - Bài viết do Admin tự đăng: tự do lựa chọn giữ vĩnh viễn không xóa hoặc hẹn giờ tự động hết hạn, tự tay xóa bất kỳ lúc nào.
  - Đã loại bỏ hoàn toàn các phần khuyến mãi/tiện ích thừa thãi.

---

## 🏗️ Kiến trúc dự án (Architecture)

Dự án áp dụng mô hình **Feature-First + Provider Pattern** giúp tách bạch hoàn toàn giữa Giao diện (Presentation), Quản lý trạng thái (State Management) và Tầng dịch vụ (Services):

```text
lib/
├── features/
│   ├── admin/             # Bảng quản trị nguồn tin, duyệt & xóa bài viết
│   ├── auth/              # Xác thực người dùng, đăng nhập Email & Google
│   ├── favorites/         # Quản lý địa điểm và bài báo yêu thích (Persistence)
│   ├── home/              # Trang chủ tổng hợp thẻ thời tiết & dòng tin tức
│   ├── navigation/        # Màn hình chờ (Splash Screen) & thanh điều hướng chính
│   ├── news/              # Danh sách tin, phân mục, đọc bài báo chi tiết
│   ├── notifications/     # Thiết lập kênh thông báo & quyền hệ thống
│   ├── profile/           # Thông tin tài khoản & nhật ký hoạt động
│   ├── search/            # Tìm kiếm thông minh phân loại Tin tức / Thời tiết
│   ├── settings/          # Chỉnh cỡ chữ, đổi ngôn ngữ Anh-Việt, dọn cache
│   └── weather/           # Dự báo khí hậu chi tiết, biểu đồ thời tiết
├── models/                # Cấu trúc dữ liệu: Article, Weather, City, RSSSource
├── services/              # Tầng gọi API: NewsService, WeatherService, ContentService
└── main.dart              # Khởi tạo ứng dụng & MultiProvider
```

---

## 🚀 Cài đặt & Trải nghiệm (Getting Started)

### 1. Tải về file APK cài đặt trực tiếp
Người dùng Android có thể tải và cài đặt trực tiếp bản phát hành mới nhất:
- 📦 **Tải về:** [`daily_news_weather.apk`](daily_news_weather.apk) *(Phiên bản v1.1.0 - 57.5 MB)*

### 2. Chạy từ mã nguồn (Developers)
```bash
# 1. Clone repository về máy
git clone https://github.com/0023411852-crypto/LTDD.git
cd LTDD

# 2. Cài đặt các thư viện phụ thuộc
flutter pub get

# 3. Chạy ứng dụng trên thiết bị / emulator
flutter run

# 4. Đóng gói file APK Release
flutter build apk --release
```

---

## 📊 So sánh phiên bản (Version Changelog)

| Tiêu chí | Bản v1.0.0 | Bản v1.1.0 |
| :--- | :--- | :--- |
| **Splash Screen** | Thanh loading tĩnh đơn giản | Logo nhịp thở phát sáng kép, thanh làm tươi mượt mà |
| **Tìm kiếm** | Chưa phân tách nguồn tin | Bộ lọc 3 chế độ (Tất cả / Tin tức / Thời tiết), lịch sử tìm kiếm |
| **Địa điểm yêu thích** | Mock data tĩnh | Lưu trữ thật 63 tỉnh/thành, cập nhật nhiệt độ thời gian thực |
| **Quản trị nguồn tin** | Danh mục cố định | Thêm/xóa nguồn RSS động, duyệt/ẩn bài viết, blacklist |
| **Thông báo** | Kênh thông báo cơ bản | Phân luồng tin nóng vs thời tiết 07:00 sáng, tương thích Android 14+ |
| **Hiệu năng & Tối ưu** | Cấu trúc Provider dùng chung | Tách Provider theo feature, tối ưu tree-shaking 98.7% font asset |

---

## 👥 Nhóm phát triển & Giấy phép
- **Repository:** [https://github.com/0023411852-crypto/LTDD](https://github.com/0023411852-crypto/LTDD)
- **Bản quyền:** Dự án được phát triển phục vụ mục đích học tập và nghiên cứu (Lập trình thiết bị di động).
