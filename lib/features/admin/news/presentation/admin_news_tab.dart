import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../models/article.dart';
import '../controllers/admin_news_controller.dart';

class AdminNewsTab extends StatelessWidget {
  final AdminNewsController controller;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final Color chipColor;
  final Color inputFillColor;

  const AdminNewsTab({
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
  Widget build(BuildContext context) {
    final filtered = controller.getFilteredArticles();
    final allArticles = controller.allArticles;
    final pendingTitles = controller.pendingTitles;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => controller.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText:
                        'Tìm kiếm trên ${allArticles.length} bài viết thật...',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF1E60F2), size: 22),
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => controller.setSearchQuery(''),
                          )
                        : null,
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['Tất cả', 'Đã duyệt', 'Chờ duyệt'].map((tab) {
                      final isSel = controller.filter == tab;
                      final count = tab == 'Tất cả'
                          ? allArticles.length
                          : tab == 'Chờ duyệt'
                              ? pendingTitles.length
                              : allArticles.length - pendingTitles.length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$tab ($count)'),
                          selected: isSel,
                          onSelected: (_) => controller.setFilter(tab),
                          selectedColor:
                              const Color(0xFF1E60F2).withOpacity(0.12),
                          checkmarkColor: const Color(0xFF1E60F2),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSel ? const Color(0xFF1E60F2) : subTextColor,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // News list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 54, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          allArticles.isEmpty
                              ? 'Đang tải dữ liệu từ RSS...'
                              : 'Không tìm thấy bài viết nào phù hợp',
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final article = filtered[index];
                      final isPending = pendingTitles.contains(article.title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 80,
                                height: 74,
                                color: borderColor,
                                child: article.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: article.imageUrl!,
                                        memCacheWidth: 240,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Color(0xFF94A3B8),
                                          size: 28,
                                        ),
                                      )
                                    : const Icon(Icons.newspaper_rounded,
                                        color: Color(0xFF1E60F2), size: 30),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: chipColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          article.source,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E60F2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        article.publishedAt != null
                                            ? '${article.publishedAt!.day}/${article.publishedAt!.month}'
                                            : 'Gần đây',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Toggle status
                                InkWell(
                                  onTap: () {
                                    controller.toggleApproval(article.title);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isPending
                                            ? 'Đã duyệt bài viết "${article.title}"'
                                            : 'Đã chuyển bài viết sang Chờ duyệt'),
                                        backgroundColor: isPending
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !isPending
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !isPending
                                            ? const Color(0xFF10B981)
                                                .withOpacity(0.3)
                                            : const Color(0xFFF59E0B)
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          !isPending
                                              ? Icons.check_circle_rounded
                                              : Icons.hourglass_top_rounded,
                                          size: 13,
                                          color: !isPending
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          !isPending ? 'Đã duyệt' : 'Chờ duyệt',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: !isPending
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Delete article
                                InkWell(
                                  onTap: () async {
                                    final confirmed = await showAppConfirmationDialog(
                                      context: context,
                                      type: AppConfirmationType.danger,
                                      icon: Icons.delete_outline_rounded,
                                      title: 'Xác nhận xóa bài viết?',
                                      description:
                                          'Bài viết "${article.title}" sẽ bị xóa vĩnh viễn khỏi danh sách bài viết.',
                                      confirmText: 'Xóa bài viết',
                                      cancelText: 'Hủy bỏ',
                                    );
                                    if (confirmed == true && context.mounted) {
                                      await controller.deleteArticlePermanently(article.title);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded,
                                                  color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text('Đã xóa bài viết khỏi ứng dụng'),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444), size: 19),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1654F0),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Đăng tin mới',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: () => showAddArticleDialog(context),
      ),
    );
  }

  void showAddArticleDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'Ban Biên Tập');
    final tagsCtrl = TextEditingController();
    final inlineImagesCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedCatLabel = 'Thời sự';
    final catOptions = [
      'Thời sự',
      'Công nghệ',
      'Kinh tế',
      'Thể thao',
      'Thế giới',
      'Giải trí',
      'Sức khỏe'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1654F0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.post_add_rounded,
                              color: Color(0xFF1654F0), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Đăng bài viết mới',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor),
                        ),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Bài viết sẽ hiển thị ngay trên toàn bộ ứng dụng',
                    style: TextStyle(fontSize: 12, color: subTextColor)),
                const Divider(height: 20),

                // Tiêu đề
                _buildDialogLabel('Tiêu đề bài viết', isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: _dialogInputDeco(
                      'Nhập tiêu đề tin tức nổi bật...', Icons.title_rounded),
                ),
                const SizedBox(height: 12),

                // Phụ đề
                _buildDialogLabel('Phụ đề / Dòng mô tả ngắn'),
                const SizedBox(height: 6),
                TextField(
                  controller: subtitleCtrl,
                  decoration: _dialogInputDeco(
                      'Dòng mô tả phụ bên dưới tiêu đề...',
                      Icons.short_text_rounded),
                ),
                const SizedBox(height: 12),

                // Danh mục
                _buildDialogLabel('Danh mục / Chuyên mục'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: catOptions.map((cat) {
                    final isSel = selectedCatLabel == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCatLabel = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF1654F0) : chipColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSel
                                  ? const Color(0xFF1654F0)
                                  : borderColor),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : subTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Tags
                _buildDialogLabel('Tags / Từ khóa'),
                const SizedBox(height: 6),
                TextField(
                  controller: tagsCtrl,
                  decoration: _dialogInputDeco(
                    'Ví dụ: công nghệ, AI, Việt Nam (cách nhau bằng dấu phẩy)',
                    Icons.sell_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // URL Ảnh
                _buildDialogLabel('URL Ảnh đại diện (thumbnail)'),
                const SizedBox(height: 6),
                TextField(
                  controller: imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _dialogInputDeco(
                      'https://example.com/image.jpg', Icons.image_rounded),
                ),
                const SizedBox(height: 12),

                // Nội dung tóm tắt
                _buildDialogLabel('Nội dung tóm tắt', isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _dialogInputDeco(
                      'Mô tả chi tiết nội dung tin tức...',
                      Icons.notes_rounded),
                ),
                const SizedBox(height: 12),

                // Nguồn / Tác giả
                _buildDialogLabel('Nguồn / Tác giả'),
                const SizedBox(height: 6),
                TextField(
                  controller: authorCtrl,
                  decoration: _dialogInputDeco(
                      'Ban Biên Tập, Tin Tức 24h...', Icons.person_rounded),
                ),
                const SizedBox(height: 12),

                // Link bài gốc
                _buildDialogLabel('Link bài viết gốc (tuỳ chọn)'),
                const SizedBox(height: 6),
                TextField(
                  controller: linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _dialogInputDeco(
                      'https://vnexpress.net/...', Icons.link_rounded),
                ),
                const SizedBox(height: 20),

                // Nút đăng
                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng nhập tiêu đề bài viết'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final newTitle = titleCtrl.text.trim();
                    final newDesc = [
                      if (subtitleCtrl.text.trim().isNotEmpty)
                        subtitleCtrl.text.trim(),
                      if (descCtrl.text.trim().isNotEmpty) descCtrl.text.trim(),
                    ].join('\n\n').isNotEmpty
                        ? [
                            if (subtitleCtrl.text.trim().isNotEmpty)
                              subtitleCtrl.text.trim(),
                            if (descCtrl.text.trim().isNotEmpty)
                              descCtrl.text.trim(),
                          ].join('\n\n')
                        : newTitle;
                    final newAuthor = authorCtrl.text.trim().isEmpty
                        ? 'Admin / $selectedCatLabel'
                        : authorCtrl.text.trim();
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toSet()
                        .toList();
                    final inlineImageUrls = inlineImagesCtrl.text
                        .split(',')
                        .map((url) => url.trim())
                        .where((url) => url.startsWith('http'))
                        .toSet()
                        .toList();
                    final imgUrl = imageUrlCtrl.text.trim().isNotEmpty
                        ? imageUrlCtrl.text.trim()
                        : null;
                    final link = linkCtrl.text.trim().isNotEmpty
                        ? linkCtrl.text.trim()
                        : 'https://news.google.com';

                    try {
                      await controller.addNewArticle(
                        Article(
                          title: newTitle,
                          link: link,
                          description: newDesc,
                          imageUrl: imgUrl,
                          source: newAuthor,
                          publishedAt: DateTime.now(),
                          category: selectedCatLabel,
                          tags: tags,
                          inlineImageUrls: inlineImageUrls,
                        ),
                      );
                    } catch (error) {
                      if (!ctx2.mounted) return;
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        SnackBar(
                          content: Text('Không thể lưu bài viết: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Đã đăng bài "$newTitle" thành công!')),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Đăng bài viết ngay',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1654F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        if (isRequired)
          const Text(' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _dialogInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF1654F0), size: 18),
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }
}
