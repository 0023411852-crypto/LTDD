# Screen Inventory & User Flows

## USER

| Mã | Màn hình | Chức năng chính | Điều hướng |
|---|---|---|---|
| U01 | Splash | Logo, kiểm tra phiên đăng nhập, điều hướng | Login/Home |
| U02 | Đăng nhập | Email/password, Google, Facebook (khi cấu hình xong), quên mật khẩu | Register/Home |
| U03 | Đăng ký | Họ tên, email, mật khẩu, xác nhận, điều khoản | Login/Home |
| U04 | Trang chủ | Tin nổi bật, danh mục, thời tiết nhanh, tin mới | News/Weather/Detail |
| U05 | Danh sách tin | Lọc danh mục, phân trang, kéo làm mới | Detail/Search |
| U06 | Chi tiết bài viết | Ảnh, nguồn, nội dung, chia sẻ, lưu yêu thích, mở bài gốc | Back/Source |
| U07 | Thời tiết hiện tại | Vị trí/thành phố, nhiệt độ, điều kiện, chỉ số | Forecast/City search |
| U08 | Dự báo | Theo giờ và 7 ngày | Weather |
| U09 | Tìm kiếm | Tìm tin, lọc, lịch sử tìm kiếm | Detail |
| U10 | Yêu thích | Danh sách bài đã lưu, bỏ lưu | Detail |
| U11 | Hồ sơ cá nhân | Thông tin tài khoản, cập nhật hồ sơ | Settings |
| U12 | Cài đặt | Theme, ngôn ngữ, thông báo, quyền riêng tư | Profile |
| U13 | Thông báo | Danh sách và trạng thái đã đọc | Detail/Weather |

## ADMIN

| Mã | Màn hình | Chức năng chính |
|---|---|---|
| A01 | Admin Dashboard | Số user, bài viết, hoạt động, biểu đồ tổng quan |
| A02 | Quản lý tin | Danh sách, tạo/sửa/xóa/ẩn, trạng thái duyệt |
| A03 | Quản lý danh mục | Tạo/sửa/xóa, bật/tắt danh mục |
| A04 | Quản lý người dùng | Tìm kiếm, xem role, khóa/mở theo quyền |
| A05 | Gửi thông báo | Tiêu đề, nội dung, đối tượng nhận, xác nhận gửi |
| A06 | Thống kê báo cáo | Khoảng thời gian, lượt xem, top danh mục, hoạt động |
| A07 | Cài đặt quản trị | Thông tin ứng dụng và cấu hình được phép |

## Luồng chính
1. Splash -> kiểm tra auth -> Home nếu đã đăng nhập, ngược lại Login.
2. Login/Register -> Firebase Authentication -> tạo/cập nhật hồ sơ user.
3. Sau đăng nhập, đọc role từ nguồn tin cậy; role admin -> AdminShell, role user -> UserShell.
4. USER không thể tự nâng role bằng cách sửa local storage hoặc request từ client.
5. Admin CRUD dữ liệu qua service/repository; Firestore Security Rules kiểm tra role ở server.

## Phạm vi chức năng theo ưu tiên
- P0: UI shell, điều hướng, news API, weather API, search, detail, favorites local, loading/error/empty.
- P1: Firebase Auth, profile, đồng bộ favorites/settings, role-based navigation.
- P2: Admin CRUD, notifications/FCM, analytics, polish và release.

## Ghi chú nội dung
Ảnh mockup chỉ tham khảo bố cục. Tên bài, nhiệt độ, thời gian, số liệu trong mockup là dữ liệu minh họa, không được hardcode làm dữ liệu thật.
