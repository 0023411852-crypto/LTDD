# Design System — Daily News & Weather Portal

## 1. Định hướng thương hiệu
- Tên: Daily News & Weather Portal.
- Sản phẩm: ứng dụng Android mobile đọc tin tức và xem thời tiết.
- Phong cách: hiện đại, rõ ràng, đáng tin cậy, thân thiện; ưu tiên khả năng đọc trên điện thoại.
- Ngôn ngữ mặc định: Tiếng Việt; hỗ trợ mở rộng đa ngôn ngữ sau này.
- USER và ADMIN dùng chung nhận diện, nhưng ADMIN có thể dùng điểm nhấn teal/green để phân biệt khu vực quản trị.

## 2. Màu sắc
Dùng các token tập trung trong `AppColors`; không khai báo màu rải rác ở từng màn hình.

| Token | Hex | Dùng cho |
|---|---|---|
| primary | `#1769E8` | CTA, tab đang chọn, liên kết |
| primaryDark | `#0B3D91` | tiêu đề đậm, vùng nhấn |
| primaryLight | `#EAF3FF` | nền chip/card nhẹ |
| secondary | `#19A7D8` | thời tiết, thông tin phụ |
| adminAccent | `#159B78` | nhãn/khu vực ADMIN |
| background | `#F5F8FE` | nền màn hình |
| surface | `#FFFFFF` | card, form, bottom sheet |
| textPrimary | `#14213D` | nội dung chính |
| textSecondary | `#66758F` | mô tả, metadata |
| divider | `#E3EAF5` | đường phân cách |
| success | `#168A55` | trạng thái thành công |
| warning | `#F2A900` | cảnh báo |
| error | `#D9363E` | lỗi/xóa/đăng xuất |

## 3. Typography
- Font ưu tiên: `Roboto` (Android native) hoặc `Inter` nếu đã tích hợp font vào assets.
- Display: 28–32sp, weight 700.
- Headline: 20–24sp, weight 700.
- Title: 16–18sp, weight 600.
- Body: 14–16sp, weight 400–500.
- Caption: 12sp, weight 400.
- Không dùng quá 3 cấp chữ trong một card; đảm bảo tương phản và hỗ trợ scale chữ.

## 4. Spacing, shape, elevation
- Lưới spacing theo bội số 4: 4, 8, 12, 16, 20, 24, 32.
- Padding màn hình: 16dp; tablet có thể tăng lên 24dp.
- Card radius: 16dp; input/button radius: 12–16dp; chip radius: 999dp.
- Khoảng cách giữa các section: 20–24dp.
- Elevation nhẹ (2–4dp); tránh shadow đậm và gradient quá nhiều.
- Khu vực chạm tối thiểu 48x48dp.

## 5. Thành phần dùng chung
Tạo component tái sử dụng, không sao chép UI giữa các màn hình:
- `AppTopBar`, `AppBottomNavigation`, `AppDrawer` (nếu cần).
- `PrimaryButton`, `SecondaryButton`, `IconButton`.
- `AppTextField`, `PasswordField`, `SearchField`.
- `NewsCard`, `FeaturedNewsCard`, `CategoryChip`, `WeatherSummaryCard`, `ForecastItem`.
- `EmptyState`, `ErrorState`, `LoadingSkeleton`, `ConfirmDialog`, `AppSnackbar`.
- `AdminMetricCard`, `AdminListTile`, `AdminFilterChips`, `AdminChartCard`.

## 6. Điều hướng
- USER: bottom navigation cố định gồm Trang chủ, Tin tức, Thời tiết, Yêu thích, Cá nhân. Tìm kiếm mở từ action/search field trên Home và News.
- ADMIN: chỉ hiển thị sau khi xác thực role; dùng AdminShell riêng trong cùng app, có Dashboard, Nội dung, Người dùng, Thông báo, Báo cáo/Cài đặt.
- Không hiển thị tab Admin cho USER.
- Back navigation phải giữ trạng thái hợp lý; không tạo nhiều bản sao route khi chuyển tab.

## 7. Hình ảnh
- Ảnh tin tức: cùng tỷ lệ theo ngữ cảnh (thumbnail 16:9 hoặc 4:3), bo góc 10–12dp, crop `BoxFit.cover`.
- Avatar: hình tròn 40–48dp; có fallback initials.
- Weather icon: dùng một bộ icon nhất quán, không trộn emoji và icon vector tùy tiện.
- Logo: sử dụng file trong `01_BRAND` làm tham khảo; cần tách logo sạch nền/asset phù hợp trước khi đưa vào production.

## 8. Quy tắc responsive và accessibility
- Thiết kế mobile-first cho Android; hỗ trợ nhiều độ rộng và safe area.
- Không để nút/form bị che bởi bàn phím; dùng scroll và resize phù hợp.
- Không dùng màu sắc làm tín hiệu duy nhất cho trạng thái.
- Tất cả icon có semantic label; hình nội dung có alt/semantic phù hợp.
- Loading, empty, error, offline phải có trạng thái riêng.
