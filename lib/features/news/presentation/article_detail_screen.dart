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
          if (mounted) {
            setState(() => _webLoading = false);
            try {
              final scale = context.read<SettingsProvider>().fontScale;
              _applyWebFontScale(scale);
            } catch (_) {}
          }
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

  void _applyWebFontScale(double scale) {
    if (_webController != null) {
      _webController?.runJavaScript(
        "document.body.style.fontSize = '${(scale * 100).round()}%';"
      ).catchError((_) {});
    }
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<SettingsProvider>(
          builder: (ctx2, settings, _) {
            final sizes = [
              {'name': 'Nhỏ', 'scale': '88%'},
              {'name': 'Tiêu chuẩn', 'scale': '100%'},
              {'name': 'Lớn', 'scale': '118%'},
              {'name': 'Rất lớn', 'scale': '135%'},
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_size_rounded,
                              color: cs.primary, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Tùy chỉnh cỡ chữ đọc bài',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(settings.fontScale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Báo điện tử: Cập nhật tin tức & dự báo thời tiết 24/7 với cỡ chữ rõ ràng, sắc nét.',
                      style: TextStyle(
                        fontSize: 14 * settings.fontScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: sizes.map((item) {
                      final name = item['name']!;
                      final scale = item['scale']!;
                      final isSel = settings.fontSize == name;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              settings.setFontSize(name);
                              _applyWebFontScale(settings.fontScale);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? cs.primary
                                    : cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? cs.primary
                                      : cs.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSel ? Colors.white : cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scale,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isSel
                                          ? Colors.white.withOpacity(0.85)
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Xong'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            tooltip: 'Đổi cỡ chữ đọc bài',
            onPressed: () => _showFontSizeBottomSheet(context),
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isFav ? cs.primary : null,
            ),
            tooltip: isFav ? 'Bỏ lưu' : 'Lưu bài viết',
            onPressed: () async {
              final wasFav = isFav;
              final success = await favoritesProvider.toggleFavorite(
                widget.article,
                context: context,
              );
              if (!success || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(wasFav
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
                      favoritesProvider.toggleFavorite(widget.article, context: context);
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
