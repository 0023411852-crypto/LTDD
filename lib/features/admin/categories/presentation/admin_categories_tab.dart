import 'package:flutter/material.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../models/article.dart';
import '../../../../services/news_service.dart';
import '../controllers/admin_categories_controller.dart';

class AdminCategoriesTab extends StatelessWidget {
  final AdminCategoriesController controller;
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const AdminCategoriesTab({
    super.key,
    required this.controller,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  IconData _catIcon(String id) {
    switch (id) {
      case 'all':
        return Icons.auto_awesome_motion_rounded;
      case 'moi-nhat':
        return Icons.fiber_new_rounded;
      case 'thoi-su':
        return Icons.public_rounded;
      case 'the-gioi':
        return Icons.language_rounded;
      case 'kinh-doanh':
        return Icons.trending_up_rounded;
      case 'cong-nghe':
        return Icons.laptop_mac_rounded;
      case 'the-thao':
        return Icons.sports_soccer_rounded;
      case 'giai-tri':
        return Icons.movie_filter_rounded;
      case 'suc-khoe':
        return Icons.favorite_rounded;
      case 'tuoi-tre':
        return Icons.newspaper_rounded;
      case 'thanh-nien':
        return Icons.article_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _catColor(String id) {
    switch (id) {
      case 'moi-nhat':
        return const Color(0xFFEF4444);
      case 'thoi-su':
        return const Color(0xFF3B82F6);
      case 'the-gioi':
        return const Color(0xFF8B5CF6);
      case 'kinh-doanh':
        return const Color(0xFFF59E0B);
      case 'cong-nghe':
        return const Color(0xFF06B6D4);
      case 'the-thao':
        return const Color(0xFF10B981);
      case 'giai-tri':
        return const Color(0xFFEC4899);
      case 'suc-khoe':
        return const Color(0xFFEF4444);
      case 'tuoi-tre':
        return const Color(0xFFEA580C);
      case 'thanh-nien':
        return subTextColor;
      default:
        return const Color(0xFF1E60F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = controller.categories;
    final selectedCat = controller.selectedCategory;
    final selectedCatIds = controller.selectedCategoryIds;
    final isLoading = controller.isLoading;

    final enabledCount = categories.where((c) => c.isEnabled).length;

    return Scaffold(
      backgroundColor: bgColor,
      body: categories.isEmpty && !isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E60F2).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rss_feed_rounded,
                          size: 54, color: Color(0xFF1E60F2)),
                    ),
                    const SizedBox(height: 18),
                    Text('Chưa kết nối nguồn tin RSS nào',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor)),
                    const SizedBox(height: 10),
                    Text(
                      'Hệ thống hiện không cài sẵn nguồn RSS mặc định trong mã nguồn. Bạn có thể tự do kết nối các nguồn tin từ bên ngoài (VnExpress, Tuổi Trẻ, Thanh Niên, Dân Trí...) theo danh mục bạn muốn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.5, color: subTextColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCategoryDialog(context),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text('Thêm nguồn tin mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E60F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản trị nguồn tin RSS ($enabledCount/${categories.length} đang bật)',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor),
                          ),
                          Text(
                            'Gạt công tắc để Bật/Tắt nguồn tin lấy về ứng dụng',
                            style:
                                TextStyle(fontSize: 12, color: subTextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Color(0xFF1654F0)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Nguồn: RSS Realtime',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E60F2))),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Bar
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E60F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 17),
                        label: const Text(
                          'Thêm nguồn mới',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showAddCategoryDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                        label: const Text(
                          'Xóa tất cả',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final confirmed = await showAppConfirmationDialog(
                            context: context,
                            type: AppConfirmationType.danger,
                            icon: Icons.delete_sweep_rounded,
                            title: 'Xóa toàn bộ nguồn tin?',
                            description:
                                'Bạn có chắc muốn xóa sạch tất cả nguồn tin RSS đã kết nối khỏi hệ thống không?',
                            confirmText: 'Xóa sạch',
                            cancelText: 'Hủy bỏ',
                          );
                          if (confirmed == true && context.mounted) {
                            await controller.restoreDefaultCategories();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa sạch danh sách nguồn tin RSS'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final allEnabled = categories.isNotEmpty &&
                        categories.every((c) => c.isEnabled);
                    final enabledCount =
                        categories.where((c) => c.isEnabled).length;

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(
                                color: allEnabled
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1654F0),
                                width: 1.2,
                              ),
                              backgroundColor: allEnabled
                                  ? const Color(0xFF10B981).withOpacity(0.08)
                                  : const Color(0xFF1654F0).withOpacity(0.06),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                              allEnabled
                                  ? Icons.check_circle_rounded
                                  : Icons.select_all_rounded,
                              size: 18,
                              color: allEnabled
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1654F0),
                            ),
                            label: Text(
                              allEnabled
                                  ? 'Đang bật tất cả (${categories.length}) • Bấm tắt chừa 1 nguồn'
                                  : 'Chọn bật tất cả ($enabledCount/${categories.length} đang bật)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: allEnabled
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1654F0),
                              ),
                            ),
                            onPressed: categories.isEmpty
                                ? null
                                : () async {
                                    final turnedAllOn = await controller
                                        .toggleAllCategoriesEnabled();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          turnedAllOn
                                              ? 'Đã BẬT TẤT CẢ ${categories.length} nguồn tin RSS!'
                                              : 'Đã tắt các nguồn khác, giữ lại 1 nguồn: "${categories.first.label}"!',
                                        ),
                                        backgroundColor: turnedAllOn
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF1E60F2),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Categories list
                ...categories.map((cat) {
                  final isChecked = selectedCatIds.contains(cat.id);
                  final isPrimary = selectedCat.id == cat.id;
                  final color = _catColor(cat.id);

                  final isEnabled = cat.isEnabled;

                  return Opacity(
                    opacity: isEnabled ? 1.0 : 0.65,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isEnabled ? surfaceColor : surfaceColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEnabled
                              ? (isChecked ? const Color(0xFF1E60F2) : borderColor)
                              : borderColor.withOpacity(0.5),
                          width: isChecked && isEnabled ? 1.5 : 1.0,
                        ),
                        boxShadow: isEnabled
                            ? [
                                const BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final success = await controller.toggleCategoryEnabled(cat.id);
                          if (!context.mounted) return;
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hệ thống cần duy trì ít nhất 1 nguồn tin hoạt động!'),
                                backgroundColor: Color(0xFFF59E0B),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !cat.isEnabled
                                    ? 'Đã BẬT nguồn tin "${cat.label}"'
                                    : 'Đã TẮT nguồn tin "${cat.label}"',
                              ),
                              backgroundColor: !cat.isEnabled
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade700,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? color
                                    : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_catIcon(cat.id),
                                  color: isChecked ? Colors.white : color,
                                  size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: cat.isEnabled ? (isChecked ? color : textColor) : subTextColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: cat.isEnabled
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF94A3B8),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(
                                            cat.isEnabled
                                                ? 'ĐANG LẤY TIN'
                                                : 'ĐÃ TẮT',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    cat.source,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isChecked
                                            ? color.withOpacity(0.8)
                                            : subTextColor,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    cat.rssUrl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E60F2)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.maxArticles > 0
                                              ? 'Tối đa: ${cat.maxArticles} bài'
                                              : 'Không giới hạn tin',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF1E60F2),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.retentionDays > 0
                                              ? 'Lưu ${cat.retentionDays} ngày'
                                              : 'Lưu vĩnh viễn',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Nút cấu hình nguồn (Số lượng & Thời gian lưu)
                            IconButton(
                              icon: const Icon(Icons.tune_rounded,
                                  color: Color(0xFF1E60F2), size: 20),
                              tooltip: 'Cấu hình số lượng & thời gian lưu',
                              onPressed: () =>
                                  _showSourceSettingsDialog(context, cat),
                            ),

                            // Nút xóa nguồn
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444), size: 20),
                              tooltip: 'Xóa nguồn này',
                              onPressed: () async {
                                final confirmed = await showAppConfirmationDialog(
                                  context: context,
                                  type: AppConfirmationType.danger,
                                  icon: Icons.delete_outline_rounded,
                                  title: 'Xác nhận xóa nguồn tin?',
                                  description:
                                      'Bạn có chắc muốn xóa nguồn tin "${cat.label}" (${cat.source}) khỏi hệ thống không?',
                                  confirmText: 'Xóa nguồn',
                                  cancelText: 'Hủy bỏ',
                                );
                                if (confirmed == true && context.mounted) {
                                  await controller.deleteCategory(cat.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Đã xóa nguồn tin "${cat.label}"'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            // Công tắc BẬT / TẮT nguồn tin (Enable / Disable RSS)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 30,
                                  child: Switch(
                                    value: cat.isEnabled,
                                    thumbColor:
                                        WidgetStateProperty.resolveWith<Color>(
                                            (states) => Colors.white),
                                    trackColor:
                                        WidgetStateProperty.resolveWith<Color>(
                                      (states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return const Color(0xFF10B981);
                                        }
                                        return isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1);
                                      },
                                    ),
                                    trackOutlineColor:
                                        WidgetStateProperty.all(Colors.transparent),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) async {
                                      final success = await controller
                                          .toggleCategoryEnabled(cat.id);
                                      if (!context.mounted) return;
                                      if (!success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Hệ thống cần duy trì ít nhất 1 nguồn tin hoạt động!'),
                                            backgroundColor: Color(0xFFF59E0B),
                                            duration: Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            val
                                                ? 'Đã BẬT nguồn tin "${cat.label}"'
                                                : 'Đã TẮT nguồn tin "${cat.label}"',
                                          ),
                                          backgroundColor: val
                                              ? const Color(0xFF10B981)
                                              : Colors.grey.shade700,
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat.isEnabled ? 'Đang bật' : 'Đã tắt',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: cat.isEnabled
                                        ? const Color(0xFF10B981)
                                        : subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final sourceCtrl = TextEditingController(text: 'VnExpress');
    final urlCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141E33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E60F2).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_circle_rounded,
                  color: Color(0xFF1E60F2), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thêm nguồn tin mới',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập thông tin chuyên mục và đường dẫn RSS để tự động lấy tin tức thời gian thực.',
                style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên chuyên mục *',
                  hintText: 'Ví dụ: Xe, Du lịch, Giáo dục...',
                  prefixIcon: const Icon(Icons.label_outline_rounded,
                      color: Color(0xFF1E60F2), size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên báo / Nguồn tin *',
                  hintText: 'Ví dụ: VnExpress, Tuổi Trẻ, Thanh Niên...',
                  prefixIcon: const Icon(Icons.business_rounded,
                      color: Color(0xFF1E60F2), size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Đường dẫn RSS Link *',
                  hintText: 'https://vnexpress.net/rss/...',
                  prefixIcon: const Icon(Icons.rss_feed_rounded,
                      color: Color(0xFF1E60F2), size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Hủy bỏ'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E60F2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Thêm nguồn'),
            onPressed: () async {
              final label = labelCtrl.text.trim();
              final source = sourceCtrl.text.trim();
              final url = urlCtrl.text.trim();

              if (label.isEmpty || source.isEmpty || url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đầy đủ các thông tin bắt buộc.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (!url.startsWith('https://') && !url.startsWith('http://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đường dẫn RSS phải bắt đầu bằng https:// hoặc http://'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final slug = label
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^\w\s-]'), '')
                  .replaceAll(RegExp(r'\s+'), '-');
              final newId = 'custom-$slug-${DateTime.now().millisecondsSinceEpoch % 10000}';

              Navigator.pop(ctx);

              await controller.addCategory(
                label: label,
                rssUrl: url,
                source: source,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm nguồn tin "$label" thành công!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Hộp thoại cấu hình số lượng tin tối đa và thời gian giữ lại bài viết cho từng nguồn
  void _showSourceSettingsDialog(BuildContext context, NewsCategory cat) {
    int maxArticles = cat.maxArticles;
    int retentionDays = cat.retentionDays;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF141E33) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E60F2).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF1E60F2), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cấu hình nguồn tin',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '${cat.label} (${cat.source})',
                      style: TextStyle(fontSize: 12, color: subTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Số lượng tin bài tối đa
                const Text(
                  'Số lượng bài tối đa giữ lại:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Giới hạn số lượng bài nạp từ nguồn này để tối ưu tốc độ và dung lượng',
                  style: TextStyle(fontSize: 11.5, color: subTextColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    (15, '15 bài'),
                    (30, '30 bài'),
                    (50, '50 bài'),
                    (100, '100 bài'),
                    (0, 'Không giới hạn'),
                  ].map((opt) {
                    final isSel = maxArticles == opt.$1;
                    return ChoiceChip(
                      label: Text(opt.$2),
                      selected: isSel,
                      selectedColor: const Color(0xFF1E60F2),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : textColor,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          maxArticles = opt.$1;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 2. Thời gian giữ lại bài viết
                const Text(
                  'Thời gian giữ lại bài tin tức:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Các bài báo cũ hơn số ngày này sẽ tự động được dọn dẹp khỏi nguồn',
                  style: TextStyle(fontSize: 11.5, color: subTextColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    (1, '1 ngày'),
                    (3, '3 ngày'),
                    (7, '7 ngày'),
                    (14, '14 ngày'),
                    (30, '30 ngày'),
                    (0, 'Lưu vĩnh viễn'),
                  ].map((opt) {
                    final isSel = retentionDays == opt.$1;
                    return ChoiceChip(
                      label: Text(opt.$2),
                      selected: isSel,
                      selectedColor: const Color(0xFF10B981),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : textColor,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          retentionDays = opt.$1;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy', style: TextStyle(color: subTextColor)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E60F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Lưu cấu hình'),
              onPressed: () async {
                Navigator.pop(ctx);
                await controller.updateCategorySettings(
                  categoryId: cat.id,
                  maxArticles: maxArticles,
                  retentionDays: retentionDays,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật cấu hình cho nguồn "${cat.label}"!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
