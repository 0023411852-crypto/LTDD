# UI Consistency & QA Checklist

- [ ] Tất cả màn hình dùng chung `ThemeData` và token trong `AppColors`.
- [ ] Typography, radius, spacing, button height và input style nhất quán.
- [ ] USER bottom navigation giống nhau trên các tab chính.
- [ ] ADMIN có AdminShell riêng; không lẫn bottom nav USER.
- [ ] Logo, app icon, splash và auth dùng cùng một bộ nhận diện.
- [ ] Có loading, empty, error, offline và retry cho từng nguồn dữ liệu.
- [ ] Không có dữ liệu mẫu giả được trình bày như dữ liệu live.
- [ ] Các form có validation, thông báo lỗi tiếng Việt và trạng thái loading.
- [ ] Mọi thao tác xóa/khóa/gửi thông báo có xác nhận phù hợp.
- [ ] Không đặt secret/API secret trong app Flutter.
- [ ] Firestore rules kiểm tra `request.auth` và role admin phía server.
- [ ] Test trên nhiều kích thước Android, keyboard, safe area, dark mode nếu hỗ trợ.
- [ ] Chạy `dart format`, `flutter analyze`, `flutter test` trước bàn giao.
