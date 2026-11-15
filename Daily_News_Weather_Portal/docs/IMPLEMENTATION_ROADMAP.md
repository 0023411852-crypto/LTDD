# Lộ trình triển khai theo sprint

| Sprint | Nội dung | Kết quả cần có |
|---|---|---|
| 0 — Audit | Đọc repo, chạy app, xác định Firebase/API/state/router | Báo cáo hiện trạng, không sửa code |
| 1 — Nền tảng | Theme Material 3, cấu trúc feature, routing, models | App shell và điều hướng |
| 2 — Tin tức | Home, feed, category, article detail, search | Tin thật, loading/error/empty |
| 3 — Thời tiết | Vị trí, thành phố, hiện tại, theo giờ, 7 ngày | Weather screens hoàn chỉnh |
| 4 — Cá nhân | Auth, profile, favorites, settings | User flows và đồng bộ |
| 5 — Admin | Role, dashboard, news/category/user management | Admin flows có bảo vệ |
| 6 — Thông báo | Notification center, FCM, lịch sử gửi | Push và in-app notification |
| 7 — QA & bàn giao | Test, accessibility, tối ưu, APK, tài liệu | Bản chạy ổn định và hướng dẫn |

## Definition of Done mỗi màn hình
- Có mockup/acceptance criteria; UI đúng Material 3 và kích thước điện thoại.
- Có loading, error, empty và success state.
- Có validate input, xử lý back/navigation và accessibility label cơ bản.
- Có test logic/repository cần thiết; `dart format`, `flutter analyze`, `flutter test`.
- Không hardcode dữ liệu demo khi đã tích hợp API/Firebase; nếu demo thì ghi rõ.
