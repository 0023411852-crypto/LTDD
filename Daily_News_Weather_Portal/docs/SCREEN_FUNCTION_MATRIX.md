# Ma trận giao diện và chức năng

## A. Giao diện người dùng
| Mã | Màn hình | Chức năng chính | Dữ liệu/điều hướng | Mockup |
|---|---|---|---|---|
| U01 | Khởi động / Splash | Hiển thị nhận diện, kiểm tra phiên đăng nhập | Auth state → Home/Login | `design/brand/app_icon_concept.png` |
| U02 | Đăng nhập | Email/mật khẩu, Google nếu cấu hình, quên mật khẩu | Firebase Auth | `design/screens/user/06_login_full_mockup.png` |
| U03 | Đăng ký | Họ tên, email, mật khẩu, xác nhận, điều khoản | Firebase Auth + users/{uid} | `design/screens/user/07_register_full_mockup.png` |
| U04 | Trang chủ | Thời tiết tóm tắt, tin nổi bật, danh mục, tin mới | News API + Weather API | `01_home.png` |
| U05 | Danh sách tin | Lọc danh mục, phân trang/làm mới | News API | `02_news_list.png` |
| U06 | Chi tiết bài viết | Ảnh, tiêu đề, nguồn, nội dung/tóm tắt, chia sẻ, lưu | News item + external source | `11_article_detail_reference.png` |
| U07 | Thời tiết | Hiện tại, độ ẩm, gió, áp suất, theo giờ, 7 ngày | Weather API | `03_weather.png` |
| U08 | Tìm kiếm | Tìm tin, lọc, lịch sử và xóa lịch sử | News API + local storage | `04_search.png` |
| U09 | Yêu thích | Danh sách đã lưu, bỏ lưu | Local DB; Firestore khi đăng nhập | `05_favorites.png` |
| U10 | Hồ sơ cá nhân | Xem/sửa tên, email, avatar, đăng xuất | Firebase Auth + Firestore | `08_profile.png` |
| U11 | Cài đặt | Sáng/tối, thông báo, ngôn ngữ, quyền riêng tư | SharedPreferences/Firestore | `09_settings.png` |
| U12 | Thông báo | Danh sách, trạng thái đã đọc, mở nội dung | FCM + Firestore | `10_notifications.png` |

## B. Giao diện quản trị Admin
| Mã | Màn hình | Chức năng chính | Quyền | Mockup |
|---|---|---|---|---|
| A01 | Dashboard | KPI, hoạt động gần đây, lối tắt quản trị | admin | `01_admin_dashboard.png` |
| A02 | Quản lý tin tức | Tạo/sửa/ẩn/xuất bản bài viết do app quản lý | admin/editor | `02_news_management.png` |
| A03 | Quản lý danh mục | Tạo/sửa/xóa mềm/sắp xếp danh mục | admin | `03_category_management.png` |
| A04 | Quản lý người dùng | Tìm, xem trạng thái, khóa/mở theo chính sách | admin | `04_user_management.png` |
| A05 | Gửi thông báo | Soạn nội dung, chọn đối tượng, gửi và xem lịch sử | admin | `05_notification_management.png` |
| A06 | Thống kê | Lượt đọc, người dùng mới, danh mục phổ biến | admin | `06_analytics.png` |

## C. Luồng điều hướng đề xuất
- USER: Splash → (Login hoặc Home) → tab Trang chủ / Tin tức / Thời tiết / Yêu thích / Cá nhân. Tìm kiếm mở từ biểu tượng search trên Home/News.
- ADMIN: đăng nhập bằng tài khoản có role admin → tab/khu vực Quản trị → Dashboard → Tin tức / Danh mục / Người dùng / Thông báo / Thống kê. Admin vẫn có thể xem các màn hình USER.
- User thường không được truy cập route admin bằng deep link hoặc sửa state trên client. Backend phải xác minh role.
