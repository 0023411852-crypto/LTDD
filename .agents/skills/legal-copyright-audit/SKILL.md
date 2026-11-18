---
name: legal-copyright-audit
description: Quy trình tự động kiểm tra bản quyền thư viện mã nguồn mở, tài nguyên media và tuân thủ luật bảo vệ dữ liệu trước khi phát hành ứng dụng thương mại.
---

# QUY TRÌNH KIỂM TOÁN BẢN QUYỀN & PHÁP LÝ ỨNG DỤNG

Khi người dùng yêu cầu kiểm tra bản quyền, giấy phép hoặc tính pháp lý của dự án, hãy thực hiện tuần tự 4 bước sau và xuất kết quả ra một **Artifact (Báo cáo kiểm toán)**:

## Bước 1: Quét giấy phép thư viện bên thứ ba (Dependencies)
- Sử dụng công cụ Terminal tích hợp để kiểm tra hệ sinh thái của dự án hiện tại:
  - Nếu có tệp `package.json` (Node.js / React Native): Chạy lệnh `npx license-checker --summary` và `npx license-checker --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD"`.
  - Nếu có tệp `pubspec.yaml` (Flutter): Kiểm tra các gói phụ thuộc bằng lệnh `flutter pub deps` hoặc dùng Trivy (`trivy fs --scanners license .`) nếu máy đã cài đặt.
- Liệt kê toàn bộ các thư viện có giấy phép lạ, chưa xác định (`UNKNOWN`) hoặc thuộc nhóm `GPL/AGPL/LGPL` và đề xuất thư viện thay thế dùng giấy phép MIT/Apache-2.0.

## Bước 2: Rà soát luồng thu thập dữ liệu & Chính sách kho ứng dụng
- Quét toàn bộ mã nguồn để lập danh sách các quyền hệ thống đang yêu cầu (Camera, Vị trí GPS, Danh bạ, Bộ nhớ) trong `AndroidManifest.xml`, `Info.plist`, hoặc `package.json`.
- Kiểm tra xem dự án đã có:
  1. Màn hình hoặc chức năng **Xóa tài khoản & Dữ liệu người dùng** hay chưa.
  2. Màn hình hiển thị **Giấy phép mã nguồn mở (Open Source Licenses)** trong phần Cài đặt của app hay chưa.
  3. Cơ chế xin phép người dùng (Consent) rõ ràng trước khi thu thập dữ liệu cá nhân theo Nghị định 13/2023/NĐ-CP và GDPR.

## Bước 3: Kiểm tra tài nguyên đa phương tiện (Fonts, Images, Audio)
- Liệt kê toàn bộ các tệp trong thư mục `assets/` (phông chữ `.ttf/.otf`, hình ảnh, âm thanh).
- Kiểm tra xem trong thư mục tài nguyên có tệp `LICENSE.txt` đi kèm không, hoặc cảnh báo các phông chữ/tài nguyên không thuộc nguồn miễn phí thương mại (như Google Fonts).

## Bước 4: Tổng hợp báo cáo (Walkthrough Artifact)
- Tạo một báo cáo chi tiết phân loại rủi ro theo 3 mức độ: **Nghiêm trọng (Cần sửa trước khi build)**, **Cảnh báo (Cần bổ sung giấy tờ/thông báo)**, và **An toàn**.
