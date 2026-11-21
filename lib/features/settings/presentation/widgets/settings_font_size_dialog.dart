import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/features/settings/providers/settings_provider.dart';

class SettingsFontSizeDialog {
  static const List<Map<String, dynamic>> _fontSizeOptions = [
    {'label': 'Nhỏ', 'scale': 0.88, 'desc': 'Phù hợp hiển thị nhiều nội dung nhất'},
    {'label': 'Tiêu chuẩn', 'scale': 1.0, 'desc': 'Mặc định cân bằng, dễ đọc'},
    {'label': 'Lớn', 'scale': 1.18, 'desc': 'Chữ to rõ ràng, thoải mái cho mắt'},
    {'label': 'Rất lớn', 'scale': 1.35, 'desc': 'Cỡ chữ cực đại dễ đọc nhất'},
  ];

  static void show(
    BuildContext context,
    SettingsProvider settings,
    Color cardColor,
    Color textColor,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(Icons.format_size_rounded, color: primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'Cỡ chữ đọc báo',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Khối xem trước
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xem trước bài báo:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dự báo thời tiết và tin tức tổng hợp 24/7 được cập nhật liên tục với tốc độ cao.',
                            style: TextStyle(
                              fontSize: 14 * settings.fontScale,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chọn kích thước chữ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Danh sách chọn cỡ chữ
                    ..._fontSizeOptions.map((opt) {
                      final label = opt['label'] as String;
                      final desc = opt['desc'] as String;
                      final isSelected = settings.fontSize == label;

                      return InkWell(
                        onTap: () {
                          settings.setFontSize(label);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.withOpacity(0.25),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: label,
                                groupValue: settings.fontSize,
                                activeColor: primaryColor,
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setFontSize(val);
                                    setState(() {});
                                  }
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? primaryColor : textColor,
                                      ),
                                    ),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textColor.withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Hoàn tất', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
