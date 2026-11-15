import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _breakingNewsNotif = true;
  bool _weatherNotif = true;
  bool _promoNotif = false;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Giao diện ─────────────────────────────────────────────
          _SectionHeader(label: 'Hiển thị'),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: isDark,
                onChanged: (val) => tp.setThemeMode(
                    val ? ThemeMode.dark : ThemeMode.light),
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Giao diện tối'),
                dense: true,
              ),
              Divider(height: 1, color: cs.outlineVariant),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Ngôn ngữ'),
                trailing: Text('Tiếng Việt',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
                dense: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Thông báo ─────────────────────────────────────────────
          _SectionHeader(label: 'Thông báo'),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: _breakingNewsNotif,
                onChanged: (v) =>
                    setState(() => _breakingNewsNotif = v),
                secondary: const Icon(Icons.newspaper_outlined),
                title: const Text('Tin tức nổi bật'),
                dense: true,
              ),
              Divider(height: 1, color: cs.outlineVariant),
              SwitchListTile(
                value: _weatherNotif,
                onChanged: (v) =>
                    setState(() => _weatherNotif = v),
                secondary: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Dự báo thời tiết'),
                dense: true,
              ),
              Divider(height: 1, color: cs.outlineVariant),
              SwitchListTile(
                value: _promoNotif,
                onChanged: (v) =>
                    setState(() => _promoNotif = v),
                secondary: const Icon(Icons.card_giftcard_outlined),
                title: const Text('Khuyến mại'),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tài khoản ─────────────────────────────────────────────
          _SectionHeader(label: 'Tài khoản'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Bảo mật'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chưa triển khai')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Về ứng dụng ───────────────────────────────────────────
          _SectionHeader(label: 'Về ứng dụng'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Phiên bản'),
                trailing: Text('1.0.0',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
                dense: true,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outlineVariant),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () {},
              ),
              Divider(height: 1, color: cs.outlineVariant),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}
