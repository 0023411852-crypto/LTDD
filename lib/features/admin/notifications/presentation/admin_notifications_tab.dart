import 'package:flutter/material.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../controllers/admin_notifications_controller.dart';

class AdminNotificationsTab extends StatefulWidget {
  final AdminNotificationsController controller;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final Color chipColor;
  final Color inputFillColor;

  const AdminNotificationsTab({
    super.key,
    required this.controller,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.chipColor,
    required this.inputFillColor,
  });

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final history = controller.broadcastHistory;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: Color(0xFF1654F0), size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phát sóng thông báo ứng dụng',
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: widget.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gửi thông báo đẩy đến phiên người dùng hiện tại',
                style: TextStyle(fontSize: 12.5, color: widget.subTextColor),
              ),
              const SizedBox(height: 18),

              const Text('Chủ đề thông báo *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Tin nóng', 'Thời tiết', 'Hệ thống']
                    .map((type) {
                  final isSel = controller.selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    selectedColor: const Color(0xFF1654F0),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : widget.subTextColor,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) {
                      setState(() {
                        controller.setSelectedType(type);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              const Text('Tiêu đề *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Cập nhật tin bão mới nhất hôm nay...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Nội dung chi tiết *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nội dung thông báo gửi đến người dùng...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 18),

              // Xem trước Live Preview
              Text(
                'Xem trước thông báo (Live Preview):',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: widget.subTextColor),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.inputFillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 36,
                        height: 36,
                        color: const Color(0xFF1654F0),
                        child: const Icon(Icons.notifications_active_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'DAILY PORTAL',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: widget.subTextColor,
                                    letterSpacing: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1654F0).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  controller.selectedType,
                                  style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1654F0)),
                                ),
                              ),
                              const Spacer(),
                              Text('Vừa xong',
                                  style: TextStyle(
                                      fontSize: 10, color: widget.subTextColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _titleController.text.isNotEmpty
                                ? _titleController.text
                                : 'Tiêu đề thông báo mẫu',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: widget.textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bodyController.text.isNotEmpty
                                ? _bodyController.text
                                : 'Nội dung chi tiết thông báo sẽ xuất hiện ở đây...',
                            style: TextStyle(
                                fontSize: 12, color: widget.subTextColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút gửi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final title = _titleController.text.trim();
                    final body = _bodyController.text.trim();

                    if (title.isEmpty || body.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final confirmed = await showAppConfirmationDialog(
                      context: context,
                      type: AppConfirmationType.notification,
                      icon: Icons.campaign_rounded,
                      title: 'Xác nhận phát sóng thông báo?',
                      description: 'Thông báo sẽ được gửi trực tiếp đến toàn bộ người dùng đang kích hoạt nhận tin.',
                      confirmText: 'Phát sóng ngay',
                      cancelText: 'Xem lại',
                      extraContent: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1654F0).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.selectedType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1654F0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: widget.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.subTextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirmed != true) return;

                    final success = controller.broadcast(
                      title: title,
                      body: body,
                      type: controller.selectedType,
                    );

                    if (success) {
                      _titleController.clear();
                      _bodyController.clear();
                      setState(() {});

                      final isAllowed = controller.selectedType == 'Tin nóng'
                          ? controller.isBreakingNewsAllowed
                          : true;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAllowed
                                      ? 'Đã phát sóng thông báo "$title" đến người dùng'
                                      : 'Đã lưu thông báo (người dùng đang tắt nhận thông báo tin nóng trong Cài đặt)',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Phát sóng thông báo ngay',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1654F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lịch sử phát sóng
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch sử thông báo đã phát (${history.length})',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Chưa có thông báo nào được phát sóng',
                      style: TextStyle(color: widget.subTextColor, fontSize: 13),
                    ),
                  ),
                )
              else
                ...history.reversed.map((n) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1654F0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notifications_active_rounded,
                              color: Color(0xFF1654F0), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: widget.textColor)),
                              Text(n['body'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12, color: widget.subTextColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Đã gửi',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
