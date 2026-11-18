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
    final categories = controller.categories;
    final selectedCat = controller.selectedCategory;
    final selectedCatIds = controller.selectedCategoryIds;
    final isLoading = controller.isLoading;

    return Scaffold(
      backgroundColor: bgColor,
      body: categories.isEmpty && !isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 60, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 14),
                  Text('Chưa tải được danh mục',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subTextColor)),
                  const SizedBox(height: 8),
                  const Text('Kiểm tra kết nối internet',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.refreshNews(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1654F0),
                        foregroundColor: Colors.white),
                  ),
                ],
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
                            'Kết nối & Đồng bộ nguồn tin (${selectedCatIds.length}/${categories.length})',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor),
                          ),
                          Text(
                            'Tích chọn nhiều danh mục để gom tin từ nhiều nguồn cùng lúc',
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
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text(
                          'Mặc định',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await controller.restoreDefaultCategories();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Đã khôi phục danh sách nguồn tin mặc định'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                              color: selectedCatIds.length == categories.length
                                  ? const Color(0xFF1654F0)
                                  : borderColor),
                          backgroundColor:
                              selectedCatIds.length == categories.length
                                  ? const Color(0xFF1654F0).withOpacity(0.08)
                                  : surfaceColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          selectedCatIds.length == categories.length
                              ? Icons.check_circle_rounded
                              : Icons.select_all_rounded,
                          size: 17,
                          color: const Color(0xFF1654F0),
                        ),
                        label: Text(
                          selectedCatIds.length == categories.length
                              ? 'Đang gom tất cả nguồn'
                              : 'Chọn tất cả (${categories.length})',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1654F0)),
                        ),
                        onPressed: () async {
                          if (selectedCatIds.length == categories.length) {
                            controller.selectCategory(categories.first);
                          } else {
                            controller.selectAllCategories();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                selectedCatIds.length == categories.length
                                    ? 'Đã đưa về chuyên mục đầu tiên'
                                    : 'Đã chọn đồng bộ tất cả chuyên mục!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Categories list
                ...categories.map((cat) {
                  final isChecked = selectedCatIds.contains(cat.id);
                  final isPrimary = selectedCat.id == cat.id;
                  final color = _catColor(cat.id);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color:
                          isChecked ? color.withOpacity(0.06) : surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isChecked ? color : borderColor,
                        width: isChecked ? 1.8 : 1.0,
                      ),
                      boxShadow: isChecked
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [
                              const BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        controller.toggleCategory(cat);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  controller.selectedCategoryIds.contains(cat.id)
                                      ? Icons.check_circle_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.selectedCategoryIds.contains(cat.id)
                                        ? 'Đã bật kết nối "${cat.label}"'
                                        : 'Đã tắt kết nối "${cat.label}"',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: color,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                                          color: isChecked ? color : textColor,
                                        ),
                                      ),
                                      if (isChecked) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(
                                              isPrimary
                                                  ? 'CHÍNH'
                                                  : 'ĐÃ KẾT NỐI',
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ],
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
                                ],
                              ),
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

                            // Checkbox
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: isChecked,
                                activeColor: color,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) async {
                                  controller.toggleCategorySelection(cat);
                                },
                              ),
                            ),
                          ],
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
}
