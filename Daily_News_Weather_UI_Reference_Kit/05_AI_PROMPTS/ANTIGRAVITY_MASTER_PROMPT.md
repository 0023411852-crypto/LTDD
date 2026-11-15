# MASTER PROMPT — Antigravity

Bạn là Senior Flutter Engineer kiêm UI/UX implementer. Hãy triển khai **Daily News & Weather Portal** thành ứng dụng **Android mobile Flutter + Dart**, dựa trên source hiện tại và toàn bộ tài liệu/hình ảnh trong `Daily_News_Weather_UI_Reference_Kit`.

## BẮT BUỘC
1. Đây là APP Android, không phải website. Không dùng React/HTML/CSS để thay thế Flutter UI.
2. Đọc `README.md`, `04_GUIDES/DESIGN_SYSTEM.md`, `SCREEN_INVENTORY.md`, `CONSISTENCY_CHECKLIST.md` trước khi code.
3. Hình ảnh trong `01_BRAND` và `02_USER_UI` là mockup tham khảo. Không đặt nguyên ảnh mockup làm background để giả lập giao diện. Hãy dựng từng thành phần bằng Flutter Widgets.
4. Tuân thủ Design System: màu, typography, spacing, radius, component và navigation dùng chung.
5. USER và ADMIN là hai role trong cùng ứng dụng Android. ADMIN chỉ hiển thị sau khi xác thực quyền.
6. Không tự ý xóa source, thay Firebase project, thay cấu trúc dữ liệu hoặc ghi đè file cấu hình trước khi audit và báo cáo.
7. Firebase project mục tiêu đã được người dùng chọn là `linh-4782e`; trước khi sửa cấu hình hãy kiểm tra source và Firebase options hiện có.
8. Không hardcode quyền admin ở client, không tin role từ local preferences; dùng custom claims hoặc cơ chế role an toàn được kiểm tra bởi Security Rules/backend.
9. Không nhúng Firebase Admin SDK/service account/private secrets vào app.

## PHASE 0 — AUDIT ONLY
- Kiểm tra cấu trúc repo, dependencies, entrypoint, routing, state management, models/services.
- Kiểm tra Firebase config hiện tại, project ID, Auth và database đang dùng.
- Liệt kê file cần tái sử dụng, file thiếu, rủi ro và kế hoạch thay đổi.
- Chưa sửa file nào cho đến khi có báo cáo audit.

## PHASE 1 — DESIGN FOUNDATION
- Tạo `AppColors`, typography, theme, spacing, radius, shared widgets.
- Tạo app shell và navigation USER/ADMIN.
- Xác nhận tất cả màn hình dùng chung component và không tự phát sinh style riêng.

## PHASE 2 — USER SCREENS
Triển khai theo `SCREEN_INVENTORY.md`: Splash, Login, Register, Home, News, Article Detail, Weather, Forecast, Search, Favorites, Profile, Settings, Notifications.
- Kết nối dữ liệu qua repository/service, không gọi API trực tiếp trong widget.
- Có loading/error/empty/offline states.
- Google/Facebook chỉ bật sau khi cấu hình provider và Android metadata hợp lệ; không để nút giả báo đăng nhập thành công.

## PHASE 3 — ADMIN SCREENS
Triển khai Dashboard, News CRUD, Category CRUD, User management, Push notification composer, Reports, Admin settings.
- Mỗi action phải có validation, loading, error handling và confirmation.
- Kiểm tra quyền tại backend/Firestore Rules, không chỉ ẩn nút ở UI.

## PHASE 4 — QA & HANDOFF
- Chạy `dart format .`, `flutter analyze`, `flutter test`.
- Kiểm tra navigation, auth, role, form validation, responsive, image loading và API failure.
- Báo cáo file đã thêm/sửa, chức năng hoàn tất/chưa hoàn tất, cấu hình người dùng cần tự thao tác.
- Chỉ build APK khi được yêu cầu hoặc khi tới bước release đã thống nhất.

## TIÊU CHÍ NGHIỆM THU
- App Android có nhận diện thống nhất trên mọi màn hình.
- Không có màn hình USER nào lộ chức năng ADMIN.
- Admin không thể bị giả mạo bằng sửa dữ liệu client.
- UI được dựng bằng Flutter Widgets, có thể tương tác thật.
- Không dùng dữ liệu giả thay cho API/Firebase khi đã tuyên bố tính năng hoàn tất.
