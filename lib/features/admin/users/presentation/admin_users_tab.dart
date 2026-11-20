import 'package:flutter/material.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../controllers/admin_users_controller.dart';

class AdminUsersTab extends StatefulWidget {
  final AdminUsersController controller;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final Color chipColor;
  final Color inputFillColor;

  const AdminUsersTab({
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
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  void _confirmDeleteUser(BuildContext context, String email, String? uid) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa tài khoản?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản "$email" khỏi hệ thống không?\n\nToàn bộ dữ liệu (yêu thích, thông báo, thông tin cá nhân) của tài khoản này sẽ bị xóa hoàn toàn.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await widget.controller.deleteUser(email, uid: uid);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã xóa tài khoản $email khỏi hệ thống.'
                        : 'Không thể xóa tài khoản này.'),
                    backgroundColor: success ? const Color(0xFF059669) : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final surfaceColor = widget.surfaceColor;
    final textColor = widget.textColor;
    final subTextColor = widget.subTextColor;
    final borderColor = widget.borderColor;
    final chipColor = widget.chipColor;
    final inputFillColor = widget.inputFillColor;

    final user = controller.user;
    final isLoggedIn = controller.isAuthenticated;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card tài khoản đang đăng nhập
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản đang đăng nhập trong phiên',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isLoggedIn
                        ? const Color(0xFF1E60F2)
                        : const Color(0xFF94A3B8),
                    child: Text(
                      isLoggedIn && controller.displayName.isNotEmpty
                          ? controller.displayName[0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? controller.displayName : 'Khách vãng lai',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? controller.email : 'Chưa đăng nhập tài khoản',
                          style: TextStyle(fontSize: 13, color: subTextColor),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${user.uid}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace'),
                          ),
                        ] else if (isLoggedIn) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${controller.uid}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLoggedIn ? const Color(0xFFECFDF5) : chipColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLoggedIn ? 'Quản trị viên' : 'Khách',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLoggedIn
                            ? const Color(0xFF059669)
                            : subTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Danh sách toàn bộ tài khoản trong hệ thống
        FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.getRegisteredUsers(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              color: Color(0xFF1E60F2), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Danh sách tài khoản hệ thống',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E60F2).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${users.length} tài khoản',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E60F2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Chưa có dữ liệu người dùng đăng ký',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: borderColor.withOpacity(0.5)),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        final uEmail = u['email'] as String? ?? '';
                        final uName = u['name'] as String? ?? 'Người dùng';
                        final hasPassword =
                            u['password'] != null || u['hasPassword'] == true;
                        final isGoogleLinked =
                            u['isGoogleLinked'] == true || u['googleId'] != null;
                        final isUserAdmin =
                            u['isAdmin'] == true || uEmail.trim().toLowerCase() == AuthProvider.rootAdminEmail;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isUserAdmin
                                    ? const Color(0xFF059669).withOpacity(0.15)
                                    : const Color(0xFF1E60F2).withOpacity(0.15),
                                child: Text(
                                  uName.isNotEmpty
                                      ? uName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isUserAdmin
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF1E60F2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      uEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (hasPassword)
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '📧 Email/Mật khẩu',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        if (isGoogleLinked)
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEA4335)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '🌐 Google Liên kết',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEA4335),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isUserAdmin
                                      ? const Color(0xFFECFDF5)
                                      : chipColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUserAdmin ? 'Admin' : 'User',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isUserAdmin
                                        ? const Color(0xFF059669)
                                        : subTextColor,
                                  ),
                                ),
                              ),
                              if (!isUserAdmin) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.redAccent, size: 20),
                                  tooltip: 'Xóa tài khoản này',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteUser(
                                    context,
                                    uEmail,
                                    u['uid'] as String?,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Hướng dẫn quản trị
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1E60F2), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cơ chế Hợp nhất Tài khoản (Account Linking)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hệ thống tự động liên kết tài khoản Email và Google Sign-In có cùng địa chỉ email thành 1 User UID duy nhất. Người dùng không bao giờ bị nhân đôi tài khoản và toàn bộ bài viết yêu thích, lịch sử đọc tin được bảo toàn 100%.',
                style: TextStyle(
                    fontSize: 12.5, color: subTextColor, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
