# Daily News & Weather Portal — UI Reference Kit

Bộ tham chiếu hình ảnh và quy chuẩn giao diện dành cho AI coding agent (Antigravity) triển khai ứng dụng **Android mobile bằng Flutter + Dart**.

## Mục tiêu
- Tất cả màn hình phải thuộc cùng một sản phẩm, cùng nhận diện thương hiệu.
- USER và ADMIN là hai khu vực/role trong **một ứng dụng Flutter Android**, không tự ý tạo website.
- Dùng hình trong thư mục này làm tài liệu tham khảo bố cục, màu sắc và thành phần; không chèn nguyên ảnh mockup làm giao diện thật.
- Ưu tiên tái sử dụng component, theme, spacing, typography và navigation.

## Thư mục
- `01_BRAND/`: concept app icon, màn hình đăng nhập và đăng ký.
- `02_USER_UI/`: bảng tham chiếu tổng thể luồng USER và ADMIN.
- `03_ADMIN_UI/`: dành cho các ảnh/mockup quản trị bổ sung; hiện ảnh tổng thể nằm ở `02_USER_UI` để giữ nguyên bảng liên kết.
- `04_GUIDES/`: design system, danh sách màn hình, quy tắc nhất quán và checklist nghiệm thu.
- `05_AI_PROMPTS/`: prompt giao việc cho Antigravity.

## Cách dùng
1. Mở `04_GUIDES/DESIGN_SYSTEM.md` trước khi code.
2. Xem `04_GUIDES/SCREEN_INVENTORY.md` để biết phạm vi màn hình và trạng thái điều hướng.
3. Đưa toàn bộ thư mục này cho Antigravity cùng source Flutter hiện tại.
4. Yêu cầu AI audit source trước, sau đó triển khai theo từng phase; không ghi đè cấu hình Firebase hoặc xóa code cũ khi chưa có báo cáo.

## Lưu ý
Hình minh họa là **visual reference/mockup**, không phải screenshot từ ứng dụng chạy thật. Nội dung chữ nhỏ trong ảnh có thể có sai lệch do tạo ảnh; khi code phải dùng nội dung tiếng Việt đúng theo đặc tả trong guides.
