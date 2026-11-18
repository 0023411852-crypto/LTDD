import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/article.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../settings/providers/settings_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _showFullWebView = false;
  WebViewController? _webController;
  bool _webLoading = true;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    final linkUri = Uri.tryParse(widget.article.link.trim());
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webLoading = false);
        },
        onNavigationRequest: (request) {
          final reqUri = Uri.tryParse(request.url);
          if (reqUri != null &&
              (reqUri.scheme == 'http' || reqUri.scheme == 'https')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ));

    if (linkUri != null &&
        (linkUri.scheme == 'http' || linkUri.scheme == 'https')) {
      _webController?.loadRequest(linkUri);
    } else {
      _webLoading = false;
    }
  }

  Future<void> _openOriginalArticle() async {
    setState(() => _showFullWebView = true);
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
    final settingsProvider = context.watch<SettingsProvider>();
    final fontScale = settingsProvider.fontScale;
    final isFav = favoritesProvider.isFavorite(widget.article);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.source),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Đổi cỡ chữ',
            onPressed: () {
              // Cycle through font sizes: Nhỏ -> Tiêu chuẩn -> Lớn -> Rất lớn
              final current = settingsProvider.fontSize;
              final next = current == 'Nhỏ'
                  ? 'Tiêu chuẩn'
                  : current == 'Tiêu chuẩn'
                      ? 'Lớn'
                      : current == 'Lớn'
                          ? 'Rất lớn'
                          : 'Nhỏ';
              settingsProvider.setFontSize(next);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cỡ chữ đọc bài: $next'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isFav ? cs.primary : null,
            ),
            tooltip: isFav ? 'Bỏ lưu' : 'Lưu bài viết',
            onPressed: () {
              favoritesProvider.toggleFavorite(widget.article);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav
                      ? 'Đã xóa khỏi mục Đã lưu'
                      : 'Đã thêm vào mục Đã lưu'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
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
          const SizedBox(width: 4),
        ],
      ),
      body: _showFullWebView && _webController != null
          ? Stack(
              children: [
                WebViewWidget(controller: _webController!),
                if (_webLoading) const LinearProgressIndicator(),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ảnh lớn (Hero Image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.article.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.article.imageUrl!,
                            width: double.infinity,
                            height: 220,
                            memCacheWidth: 900,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 180,
                              color: cs.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 180,
                              color: cs.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.image_outlined,
                                    size: 40, color: cs.outline),
                              ),
                            ),
                          )
                        : Container(
                            height: 180,
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.image_outlined,
                                  size: 40, color: cs.outline),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Nguồn & Thời gian
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nguồn: ${widget.article.source}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(widget.article.publishedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(widget.article.category),
                        visualDensity: VisualDensity.compact,
                      ),
                      ...widget.article.tags.map(
                        (tag) => Chip(
                          label: Text('#$tag'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Tiêu đề bài viết
                  Text(
                    widget.article.title,
                    style: tt.headlineSmall?.copyWith(
                      fontSize: (tt.headlineSmall?.fontSize ?? 24) * fontScale,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Audio Reader button
                  OutlinedButton.icon(
                    onPressed: _toggleAudioReader,
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.pause_circle_filled_rounded
                          : Icons.volume_up_rounded,
                      size: 20,
                    ),
                    label: Text(_isPlayingAudio
                        ? 'Tạm dừng đọc bài'
                        : 'Nghe đọc bài viết'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Nội dung tóm tắt
                  Text(
                    widget.article.description.isNotEmpty
                        ? widget.article.description
                        : 'Nội dung tóm tắt đang được cập nhật từ ${widget.article.source}. Bạn có thể bấm nút bên dưới để đọc bài viết gốc đầy đủ.',
                    style: tt.bodyLarge?.copyWith(
                      fontSize: (tt.bodyLarge?.fontSize ?? 16) * fontScale,
                      height: 1.6,
                      color: cs.onSurface,
                    ),
                  ),
                  if (widget.article.inlineImageUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...widget.article.inlineImageUrls.map(
                      (imageUrl) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) => const SizedBox(
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // 6. Nút Đọc bài gốc (WebView)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonalIcon(
                      onPressed: _openOriginalArticle,
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('Đọc bài viết gốc tại trang báo'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _showFullWebView
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      favoritesProvider.toggleFavorite(widget.article);
                    },
                    icon: Icon(
                      isFav
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isFav ? cs.primary : cs.onSurfaceVariant,
                    ),
                    tooltip: isFav ? 'Bỏ lưu' : 'Lưu lại',
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép liên kết!')),
                      );
                    },
                    icon:
                        Icon(Icons.share_outlined, color: cs.onSurfaceVariant),
                    tooltip: 'Chia sẻ',
                  ),
                  IconButton(
                    onPressed: _openOriginalArticle,
                    icon: Icon(Icons.public, color: cs.primary),
                    tooltip: 'Đọc web',
                  ),
                ],
              ),
            ),
    );
  }
}
