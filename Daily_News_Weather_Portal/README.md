# Daily News & Weather Portal — Flutter Android

Bộ tài liệu triển khai ứng dụng di động Android bằng **Flutter + Dart**. Gói gồm kế hoạch dự án, kiến trúc, danh sách chức năng theo vai trò USER/ADMIN, hướng dẫn Firebase/API, checklist kiểm thử, mockup giao diện và prompt cho Antigravity.

## Bắt đầu
1. Đọc `docs/PROJECT_PLAN.md` và `docs/SCREEN_FUNCTION_MATRIX.md`.
2. Xem mockup trong `design/screens/user/` và `design/screens/admin/`.
3. Mở `antigravity/MASTER_PROMPT.md` trong Antigravity; yêu cầu audit repo hiện tại trước, không ghi đè code hoặc đổi Firebase khi chưa được duyệt.
4. Dùng `docs/IMPLEMENTATION_ROADMAP.md` để chia sprint.

## Công nghệ mục tiêu
- Android app: Flutter + Dart, Material 3, responsive theo kích thước điện thoại.
- State management: Provider (hoặc giữ giải pháp hiện có sau khi audit).
- Backend: Firebase Authentication + Cloud Firestore; FCM cho push notification khi cấu hình backend phù hợp.
- Nguồn dữ liệu: News API/RSS và Weather API; cần kiểm tra điều khoản, giới hạn và cách bảo vệ API key.

## Lưu ý hình ảnh
Các ảnh trong `design/screens/` là **mockup tham khảo UI**, không phải màn hình đã chạy từ source Flutter. Hình Admin được minh họa theo cùng bộ nhận diện xanh-trắng.
