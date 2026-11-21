import 'package:flutter/material.dart';

class SettingsPolicyDialog {
  static void show(
    BuildContext context,
    String title,
    Color cardColor,
    Color textColor,
  ) {
    final isPrivacy = title.contains('bảo mật');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              isPrivacy
                  ? 'Ứng dụng Tin tức & Thời tiết tôn trọng và cam kết bảo vệ thông tin riêng tư của bạn.\n\n'
                      '1. Thu thập dữ liệu: Ứng dụng chỉ xin quyền vị trí GPS để dự báo thời tiết chính xác tại nơi bạn đứng và quyền thông báo để gửi các bản tin quan trọng.\n\n'
                      '2. Lưu trữ: Mọi cài đặt cá nhân và danh sách địa điểm yêu thích được lưu an toàn trực tiếp trên thiết bị của bạn.\n\n'
                      '3. Chia sẻ: Chúng tôi tuyệt đối không bán hoặc chia sẻ thông tin cá nhân của người dùng cho bất kỳ bên thứ ba nào.'
                  : 'Chào mừng bạn sử dụng dịch vụ Tin tức & Thời tiết!\n\n'
                      '1. Quyền sở hữu: Toàn bộ nội dung tin tức được tổng hợp từ các nguồn RSS uy tín theo đúng quy định pháp luật.\n\n'
                      '2. Trách nhiệm người dùng: Bạn có quyền đọc, lưu trữ và chia sẻ tin tức cá nhân. Không sử dụng ứng dụng cho các mục đích vi phạm pháp luật.\n\n'
                      '3. Cập nhật: Chúng tôi liên tục cải tiến tính năng và giao diện để mang lại trải nghiệm đọc tin tức tuyệt vời nhất cho bạn.',
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }
}
