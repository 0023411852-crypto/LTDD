# Checklist kiểm thử

## USER
- [ ] Splash điều hướng đúng theo auth state.
- [ ] Đăng ký: email sai, mật khẩu yếu, email đã tồn tại, xác nhận mật khẩu lệch.
- [ ] Đăng nhập/đăng xuất/quên mật khẩu và session persistence.
- [ ] Tin tức: tải, refresh, phân trang, lỗi mạng, nguồn bài viết.
- [ ] Chi tiết: mở nguồn gốc, lưu/bỏ lưu, chia sẻ.
- [ ] Thời tiết: quyền vị trí được cấp/từ chối, chọn thành phố, API lỗi.
- [ ] Tìm kiếm: từ khóa rỗng, không kết quả, lịch sử.
- [ ] Favorites local và đồng bộ sau đăng nhập.
- [ ] Settings: theme, notification toggle, ngôn ngữ.
- [ ] Notifications: nhận push khi foreground/background, đã đọc/chưa đọc.

## ADMIN & SECURITY
- [ ] User thường không nhìn thấy hoặc mở được Admin route.
- [ ] Gọi trực tiếp Firestore từ user thường không thể ghi dữ liệu admin.
- [ ] Admin tạo/sửa/ẩn bài và danh mục; validate dữ liệu.
- [ ] Quản lý user không cho admin tự nâng quyền qua client.
- [ ] Gửi thông báo chỉ qua backend tin cậy; có lịch sử và xử lý lỗi.
- [ ] Analytics chỉ đọc dữ liệu được phép; không lộ thông tin cá nhân.

## Release
- [ ] Không có secret/service account trong source hoặc APK.
- [ ] Android permission tối thiểu, privacy disclosure phù hợp.
- [ ] Kiểm tra màn hình nhỏ, bàn phím, xoay màn hình nếu hỗ trợ.
- [ ] `flutter analyze`, `flutter test`, build APK/AAB thành công.
