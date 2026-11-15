# Kế hoạch tổng thể dự án

## 1. Mục tiêu
Xây dựng ứng dụng **Android mobile** Daily News & Weather Portal bằng Flutter/Dart. Người dùng đọc tin tức theo danh mục, xem thời tiết hiện tại và dự báo, tìm kiếm, lưu bài yêu thích, nhận thông báo và quản lý hồ sơ. Quản trị viên có khu vực quản trị để quản lý nội dung và người dùng.

## 2. Phạm vi sản phẩm
### USER
- Xem trang chủ: thời tiết nhanh, tin nổi bật, danh mục, tin mới.
- Duyệt danh sách tin, lọc theo danh mục, mở chi tiết và nguồn gốc bài viết.
- Xem thời tiết hiện tại, theo giờ và dự báo nhiều ngày theo vị trí/thành phố.
- Tìm kiếm tin, xem/xóa lịch sử tìm kiếm.
- Lưu/bỏ lưu bài viết; đồng bộ yêu thích nếu đăng nhập.
- Đăng ký, đăng nhập, đăng xuất, quên mật khẩu; cập nhật hồ sơ.
- Cài đặt giao diện sáng/tối, ngôn ngữ, thông báo và quyền riêng tư.
- Xem thông báo tin mới, thời tiết và thông báo hệ thống.

### ADMIN
- Dashboard: tổng số người dùng, bài viết, lượt đọc và hoạt động gần đây.
- Quản lý bài viết do hệ thống sở hữu/biên tập: tạo, sửa, ẩn/xóa mềm, đánh dấu nổi bật, trạng thái bản nháp/xuất bản.
- Quản lý danh mục: tạo, sửa, sắp xếp, bật/tắt.
- Quản lý người dùng: tìm kiếm, xem trạng thái, khóa/mở tài khoản theo chính sách.
- Soạn/gửi thông báo đến tất cả hoặc nhóm người dùng.
- Báo cáo: lượt đọc, bài nổi bật, danh mục phổ biến, tăng trưởng người dùng.

## 3. Quyết định sản phẩm
- Đây là **ứng dụng Flutter Android**, không phải website. UI được xây bằng Flutter Widgets/Material 3, không dùng HTML/CSS hay XML để dựng màn hình.
- Admin nằm trong cùng app ở một nhánh điều hướng riêng, chỉ hiển thị khi tài khoản có role admin. Với triển khai thực tế quy mô lớn, có thể tách dashboard quản trị riêng sau này; không cần làm trong phiên bản đồ án.
- Tin từ API bên ngoài là dữ liệu đọc; chỉ quản trị nội dung thuộc quyền kiểm soát của ứng dụng. Không giả định có quyền sửa/xóa bài trên nguồn báo bên ngoài.
- P0 phải chạy ổn định trước; P1/P2 bổ sung sau.

## 4. Mức ưu tiên
| Ưu tiên | Phạm vi | Tiêu chí hoàn thành |
|---|---|---|
| P0 | Điều hướng, trang chủ, tin tức, chi tiết, thời tiết, tìm kiếm, yêu thích local | Luồng chính chạy trên Android, có loading/empty/error |
| P1 | Firebase Auth, hồ sơ, đồng bộ yêu thích, cài đặt, thông báo | Dữ liệu đúng người dùng, đăng nhập/đăng xuất ổn định |
| P1 | Admin dashboard, bài viết, danh mục, người dùng | Role và Security Rules chặn user thường |
| P2 | Báo cáo nâng cao, phân nhóm FCM, cache/offline | Có dữ liệu và backend phù hợp, không làm lộ quyền |

## 5. Điều kiện bàn giao
- `flutter analyze` không còn lỗi nghiêm trọng; `flutter test` chạy qua.
- Kiểm thử trên ít nhất một Android emulator và một thiết bị thật nếu có.
- Có hướng dẫn cấu hình Firebase/API, tài khoản test USER/ADMIN, sơ đồ dữ liệu, APK debug/release theo yêu cầu môn học.
- Không commit secrets, service-account key hoặc API key nhạy cảm.
