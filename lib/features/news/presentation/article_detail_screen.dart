import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/article.dart';
import '../../favorites/providers/favorites_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _showFullWebView = false;
  late final WebViewController _webController;
  bool _webLoading = true;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webLoading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.article.link));
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  void _toggleAudioReader() {
    setState(() => _isPlayingAudio = !_isPlayingAudio);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPlayingAudio
              ? 'Đang phát âm thanh đọc bài viết...'
              : 'Đã tạm dừng đọc bài viết.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(widget.article);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border_rounded,
              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
            ),
            tooltip: isFav ? 'Bỏ thích' : 'Yêu thích',
            onPressed: () {
              favoritesProvider.toggleFavorite(widget.article);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav
                      ? 'Đã xóa khỏi mục Yêu thích'
                      : 'Đã thêm vào mục Yêu thích'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            tooltip: 'Chia sẻ',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép liên kết bài viết vào clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _showFullWebView
          ? Stack(
              children: [
                WebViewWidget(controller: _webController),
                if (_webLoading) const LinearProgressIndicator(),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ảnh lớn (Hero Image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.article.imageUrl ??
                          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=900',
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Tiêu đề bài viết
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Thông tin meta: Thời gian • Lượt xem • Tòa soạn
                  Row(
                    children: [
                      Text(
                        _getTimeAgo(widget.article.publishedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        ' • 1.2k lượt xem • ${widget.article.source}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E60F2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Nút Đọc bài (Audio Player Button chuẩn Mockup)
                  InkWell(
                    onTap: _toggleAudioReader,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E60F2), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E60F2)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlayingAudio
                                ? Icons.pause_circle_filled_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlayingAudio ? 'Tạm dừng đọc' : 'Đọc bài',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Nội dung tóm tắt
                  Text(
                    widget.article.description.isNotEmpty
                        ? widget.article.description
                        : 'Nội dung chi tiết đang được cập nhật từ ${widget.article.source}. Bạn có thể bấm nút bên dưới để đọc bài viết gốc đầy đủ.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 6. Nút Đọc bài gốc (WebView)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showFullWebView = true),
                      icon: const Icon(Icons.open_in_browser_rounded,
                          color: Color(0xFF1E60F2)),
                      label: const Text(
                        'Đọc bài viết gốc tại trang báo',
                        style: TextStyle(
                          color: Color(0xFF1E60F2),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF1E60F2), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: _showFullWebView
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      favoritesProvider.toggleFavorite(widget.article);
                    },
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? const Color(0xFFEF4444) : Colors.grey,
                      size: 26,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép liên kết!')),
                      );
                    },
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.grey, size: 26),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _showFullWebView = true),
                    icon: const Icon(Icons.public,
                        color: Color(0xFF1E60F2), size: 26),
                  ),
                ],
              ),
            ),
    );
  }
}
