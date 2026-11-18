import 'package:flutter/material.dart';

enum AppConfirmationType {
  primary,
  danger,
  warning,
  success,
  notification,
}

/// Hộp thoại xác nhận & thông báo thẩm mỹ cao (Modern Glassmorphic Aesthetic Dialog)
class AppConfirmationDialog extends StatelessWidget {
  final AppConfirmationType type;
  final IconData icon;
  final String title;
  final String description;
  final Widget? extraContent;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Color? customAccentColor;

  const AppConfirmationDialog({
    super.key,
    this.type = AppConfirmationType.primary,
    required this.icon,
    required this.title,
    required this.description,
    this.extraContent,
    required this.confirmText,
    this.cancelText = 'Hủy bỏ',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.customAccentColor,
  });

  Color _getAccentColor() {
    if (customAccentColor != null) return customAccentColor!;
    switch (type) {
      case AppConfirmationType.danger:
        return const Color(0xFFEF4444);
      case AppConfirmationType.warning:
        return const Color(0xFFF59E0B);
      case AppConfirmationType.success:
        return const Color(0xFF10B981);
      case AppConfirmationType.notification:
        return const Color(0xFF0284C7);
      case AppConfirmationType.primary:
        return const Color(0xFF2563EB);
    }
  }

  List<Color> _getGradientColors(Color accent) {
    switch (type) {
      case AppConfirmationType.danger:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case AppConfirmationType.warning:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case AppConfirmationType.success:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case AppConfirmationType.notification:
        return [const Color(0xFF38BDF8), const Color(0xFF0284C7)];
      case AppConfirmationType.primary:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _getAccentColor();
    final gradient = _getGradientColors(accent);

    final cardBg = isDark ? const Color(0xFF141E33) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155).withOpacity(0.6)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.16 : 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. ICON BADGE VỚI HIỆU ỨNG GLOW KÉP
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.12),
                          ),
                        ),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 2. TIÊU ĐỀ
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. MÔ TẢ
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.48,
                        color: descColor,
                      ),
                    ),

                    // 4. NỘI DUNG MỞ RỘNG (NẾU CÓ)
                    if (extraContent != null) ...[
                      const SizedBox(height: 16),
                      extraContent!,
                    ],
                    const SizedBox(height: 24),

                    // 5. NÚT HÀNH ĐỘNG (ACTION BUTTONS)
                    Row(
                      children: [
                        // Nút Hủy
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              foregroundColor: descColor,
                            ),
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: descColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nút Xác nhận
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.32),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: onConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper hiển thị Dialog với hiệu ứng chuyển cảnh mượt mà
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required AppConfirmationType type,
  required IconData icon,
  required String title,
  required String description,
  Widget? extraContent,
  required String confirmText,
  String cancelText = 'Hủy bỏ',
  Color? customAccentColor,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) => AppConfirmationDialog(
      type: type,
      icon: icon,
      title: title,
      description: description,
      extraContent: extraContent,
      confirmText: confirmText,
      cancelText: cancelText,
      customAccentColor: customAccentColor,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onCancel: () => Navigator.of(ctx).pop(false),
    ),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}
