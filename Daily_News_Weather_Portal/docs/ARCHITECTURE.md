# Kiến trúc ứng dụng đề xuất

```text
lib/
  app/                 # MaterialApp, router, theme
  core/                # constants, errors, network, utils, widgets
  data/                # DTO, repositories, local storage
  features/
    auth/              # login, register, forgot password
    home/ news/        # feed, category, article detail
    weather/           # current, hourly, daily forecast
    search/ favorites/ # search, saved articles
    profile/ settings/ notifications/
    admin/             # dashboard, news, categories, users, push, analytics
  services/            # Firebase, news API, weather API
  shared/              # reusable components
  main.dart

```

## Nguyên tắc
- Feature-first; UI không gọi HTTP/Firebase trực tiếp mà đi qua repository/service.
- Tách model, repository, provider/state và screen/widget.
- Dùng trạng thái loading/success/empty/error rõ ràng.
- Cache thời tiết/tin gần đây; xử lý timeout, retry có giới hạn và rate limit.
- Giữ state management hiện có nếu repo đã có giải pháp ổn định; không đổi hàng loạt khi chưa audit.
- Dùng go_router hoặc router hiện tại; bảo vệ route admin bằng kiểm tra role và kiểm tra lại ở backend.
