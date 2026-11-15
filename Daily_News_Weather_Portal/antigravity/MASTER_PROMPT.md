# MASTER PROMPT — Antigravity

Bạn là senior Flutter engineer. Hãy xây dựng **ứng dụng Android mobile** “Daily News & Weather Portal” theo tài liệu trong thư mục này. Đây không phải website. UI phải dùng Flutter Widgets + Material 3; không dùng HTML/CSS/React và không dùng XML để dựng UI.

## Quy tắc bắt buộc
1. Giai đoạn đầu chỉ AUDIT repo: đọc cấu trúc, chạy app, xác định chức năng đã có/thiếu, dependencies, router/state management, Firebase project và API. Trả báo cáo trước khi sửa.
2. Không xóa/ghi đè source, không tạo lại project, không thay Firebase project hoặc ghi đè `firebase_options.dart`/`google-services.json` trước khi có phê duyệt rõ ràng. Project mục tiêu người dùng từng chọn là `linh-4782e`; hãy xác minh hiện trạng trước.
3. Giữ lại code tốt; thay đổi nhỏ, có kiểm soát; giải thích file sẽ sửa.
4. Bám `docs/SCREEN_FUNCTION_MATRIX.md`, `docs/PROJECT_PLAN.md`, `docs/API_FIREBASE_SECURITY.md` và mockup trong `design/screens/`.
5. Phân biệt USER và ADMIN. Admin route và mọi thao tác admin phải được xác thực ở backend/Security Rules; không dựa vào ẩn nút. Không cho client tự set role.
6. Tin tức API ngoài là nội dung đọc; chỉ CRUD nội dung do ứng dụng sở hữu. Không giả định được phép sửa bài từ publisher.
7. Không hardcode secret, API key nhạy cảm hay service-account key.

## Sau khi audit được duyệt
Triển khai theo `docs/IMPLEMENTATION_ROADMAP.md`: app shell → news → weather → auth/profile/favorites/settings → admin → notifications → QA/release. Mỗi sprint phải báo file thay đổi, lý do, cách test, rủi ro và kết quả `dart format`, `flutter analyze`, `flutter test`.

## Tiêu chí chất lượng
- Tiếng Việt, responsive cho điện thoại Android, Material 3, theme sáng/tối.
- Loading/error/empty/success state đầy đủ, xử lý offline và timeout cơ bản.
- Repository/service tách khỏi UI; không gọi API trực tiếp trong widget.
- Tạo test cho logic quan trọng; kiểm tra phân quyền bằng cả UI và Rules/backend.
- Không tuyên bố hoàn tất nếu chưa chạy và kiểm tra thực tế.
