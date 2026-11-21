import 'package:flutter/material.dart';
import 'package:daily_news_weather_portal/services/weather_service.dart';
import 'package:daily_news_weather_portal/features/weather/providers/weather_provider.dart';

class WeatherLocationSearchDialog {
  static Future<void> show(
    BuildContext context,
    WeatherProvider provider,
  ) async {
    final controller = TextEditingController();
    Future<List<City>>? searchFuture;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Tìm kiếm địa điểm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên xã, phường, quận, huyện, tỉnh thành...',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      final q = val.trim();
                      setState(() {
                        searchFuture = q.length < 2
                            ? null
                            : provider.searchCities(q);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: searchFuture == null
                        ? const Center(
                            child: Text(
                              'Nhập từ khóa (xã, phường, quận, huyện, tỉnh thành) để tra cứu thời tiết tại Việt Nam.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : FutureBuilder<List<City>>(
                            future: searchFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cloud_off_rounded,
                                            size: 40, color: Colors.orange),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Chưa thể kết nối tới máy chủ tra cứu. Vui lòng thử lại.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final list = snapshot.data ?? const [];
                              if (list.isEmpty) {
                                return const Center(
                                  child: Text('Không tìm thấy địa điểm nào phù hợp.'),
                                );
                              }
                              return ListView.separated(
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final city = list[i];
                                  final isIsland = city.name.contains('Hoàng Sa') ||
                                      city.name.contains('Trường Sa');
                                  return ListTile(
                                    leading: Icon(
                                      isIsland
                                          ? Icons.flag_rounded
                                          : Icons.location_on_outlined,
                                      color: isIsland
                                          ? Colors.red
                                          : const Color(0xFF1E60F2),
                                    ),
                                    title: Text(
                                      city.name,
                                      style: TextStyle(
                                        fontWeight: isIsland
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isIsland
                                            ? const Color(0xFFDC2626)
                                            : null,
                                      ),
                                    ),
                                    subtitle: isIsland
                                        ? const Text(
                                            'Lãnh thổ thiêng liêng của Việt Nam 🇻🇳',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      provider.selectCity(city);
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }
}
