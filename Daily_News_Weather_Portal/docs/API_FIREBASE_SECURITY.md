# API, Firebase và bảo mật

## Firebase
- Authentication: email/password; provider Google/Apple chỉ bật khi đã cấu hình đúng trên Firebase Console và Android.
- Cloud Firestore gợi ý: `users/{uid}`, `articles/{articleId}` (chỉ nội dung do app sở hữu), `categories/{categoryId}`, `favorites/{uid}/items/{itemId}`, `notifications/{notificationId}`, `admin_metrics/{date}`.
- Không đổi project Firebase đang dùng trước khi kiểm tra `firebase_options.dart`, `google-services.json`, `AndroidManifest.xml` và cấu hình hiện có. Project mục tiêu được người dùng chọn trước đó là `linh-4782e`; phải xác minh lại cấu hình thực tế trong repo trước khi triển khai.

## Phân quyền Admin
- Role admin phải được cấp có kiểm soát (ví dụ custom claims do môi trường tin cậy đặt, hoặc collection role chỉ backend có quyền ghi). Không cho client tự ghi `role: admin`.
- Firestore Security Rules phải kiểm tra `request.auth.uid` và role; mặc định deny, chỉ mở đúng collection/field cần thiết.
- Ẩn nút Admin trong Flutter chỉ là UX, không phải bảo mật. Mọi thao tác nhạy cảm phải được Rules/Cloud Functions hoặc backend xác thực.
- Khóa tài khoản thực sự có thể cần Firebase Admin SDK/Cloud Functions; không nhúng service account vào ứng dụng mobile.

## API ngoài
- News: adapter riêng cho News API/RSS; lưu nguồn, URL gốc, thời gian, ảnh và điều khoản sử dụng. API có thể không cho sửa/xóa nội dung.
- Weather: adapter riêng cho dịch vụ dự báo; xử lý quyền vị trí, từ chối quyền, chọn thành phố thủ công và đơn vị nhiệt độ.
- Không commit API key; dùng cấu hình môi trường/remote config phù hợp. Key nhúng trong mobile có thể bị trích xuất, nên giới hạn theo provider và proxy qua backend nếu cần bảo vệ.

## FCM
- Push notification nên gửi từ môi trường tin cậy (Cloud Functions/server), không cho client tự gửi broadcast. Lưu token theo UID, xử lý token hết hạn và opt-in/opt-out.
