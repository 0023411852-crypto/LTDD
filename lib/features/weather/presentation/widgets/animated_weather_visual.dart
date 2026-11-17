import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget biểu diễn biểu tượng thời tiết chuyển động (Animated Weather Visual)
/// Thiết kế 3D vector mượt mà, rực rỡ, phù hợp từng loại thời tiết.
class AnimatedWeatherVisual extends StatefulWidget {
  final int? weatherCode;
  final bool isDaytime;
  final double size;

  const AnimatedWeatherVisual({
    super.key,
    required this.weatherCode,
    required this.isDaytime,
    this.size = 100,
  });

  @override
  State<AnimatedWeatherVisual> createState() => _AnimatedWeatherVisualState();
}

class _AnimatedWeatherVisualState extends State<AnimatedWeatherVisual>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _flashController;

  bool get _isRain =>
      const [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(widget.weatherCode);
  bool get _isStorm => const [95, 96, 99].contains(widget.weatherCode);
  bool get _isSnow =>
      const [71, 73, 75, 77, 85, 86].contains(widget.weatherCode);
  bool get _isCloudy => const [1, 2, 3].contains(widget.weatherCode);
  bool get _isFog => const [45, 48].contains(widget.weatherCode);
  bool get _isClear => widget.weatherCode == 0;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size / 100;
    final isDay = widget.isDaytime;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 1.25,
        height: widget.size * 1.15,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _mainController,
            _pulseController,
            _flashController,
          ]),
          builder: (context, child) {
            final t = _mainController.value;
            final pulse = _pulseController.value;
            final flash = _flashController.value;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Mặt trời hoặc mặt trăng hậu cảnh
                if (isDay && (_isClear || _isCloudy || _isFog))
                  Positioned(
                    right: widget.size * (_isClear ? 0.25 : 0.08),
                    top: widget.size * (_isClear ? 0.12 : 0.02),
                    child: _buildGlowingSun(scale, pulse, t),
                  ),

                if (!isDay && (_isClear || _isCloudy || _isFog))
                  Positioned(
                    right: widget.size * (_isClear ? 0.25 : 0.08),
                    top: widget.size * (_isClear ? 0.12 : 0.02),
                    child: _buildGlowingMoon(scale, pulse, t),
                  ),

                // 2. Các hạt mưa / sấm chớp / tuyết rơi
                if (_isRain || _isStorm)
                  ..._buildRainDrops(scale, t, isHeavy: _isStorm),

                if (_isStorm)
                  Positioned(
                    bottom: widget.size * 0.04,
                    right: widget.size * 0.38,
                    child: _buildLightning(scale, flash),
                  ),

                if (_isSnow) ..._buildSnowFlakes(scale, t),

                if (_isFog) ..._buildFogLayers(scale, t),

                // 3. Đám mây tiền cảnh (nếu có mây / mưa / bão / tuyết)
                if (!_isClear && !_isFog)
                  Positioned(
                    left: widget.size * 0.05,
                    bottom: widget.size * 0.12,
                    child: _buildPuffyCloud(scale, pulse, isStorm: _isStorm),
                  ),

                // 4. Nếu trời quang đãng hoàn toàn: Thêm quầng hào quang xoay
                if (_isClear)
                  Positioned(
                    child: isDay
                        ? _buildSunRays(scale, t)
                        : _buildMoonStars(scale, t),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- MẶT TRỜI TỎA ÁNH SÁNG RỰC RỠ ---
  Widget _buildGlowingSun(double scale, double pulse, double rotate) {
    final sunSize = 58.0 * scale;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Quầng phát sáng xa
        Container(
          width: sunSize * (1.35 + pulse * 0.15),
          height: sunSize * (1.35 + pulse * 0.15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFE082).withOpacity(0.55),
                const Color(0xFFFFB300).withOpacity(0.20),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Quả cầu mặt trời gradient
        Container(
          width: sunSize,
          height: sunSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF9C4),
                Color(0xFFFFD54F),
                Color(0xFFFF9800),
                Color(0xFFF57C00),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withOpacity(0.65),
                blurRadius: 18 * scale,
                spreadRadius: 2 * scale,
              ),
              BoxShadow(
                color: const Color(0xFFFFE082).withOpacity(0.9),
                blurRadius: 8 * scale,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TIA NẮNG XOAY NHẸ QUANH MẶT TRỜI ---
  Widget _buildSunRays(double scale, double t) {
    return Transform.rotate(
      angle: t * math.pi * 2,
      child: SizedBox(
        width: 105 * scale,
        height: 105 * scale,
        child: CustomPaint(
          painter: _SunRaysPainter(scale: scale),
        ),
      ),
    );
  }

  // --- MẶT TRĂNG VÀ HÀO QUANG ĐÊM ---
  Widget _buildGlowingMoon(double scale, double pulse, double t) {
    final moonSize = 54.0 * scale;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Quầng hào quang xanh bạc dịu dàng
        Container(
          width: moonSize * (1.4 + pulse * 0.1),
          height: moonSize * (1.4 + pulse * 0.1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFC7D2FE).withOpacity(0.4),
                const Color(0xFF818CF8).withOpacity(0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Mặt trăng khuyết 3D
        Container(
          width: moonSize,
          height: moonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE0E7FF),
                Color(0xFFC7D2FE),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF818CF8).withOpacity(0.55),
                blurRadius: 16 * scale,
                spreadRadius: 2 * scale,
              ),
            ],
          ),
          child: Align(
            alignment: const Alignment(-0.25, -0.15),
            child: Icon(
              Icons.nightlight_round,
              color: const Color(0xFF4338CA),
              size: moonSize * 0.65,
            ),
          ),
        ),
      ],
    );
  }

  // --- CÁC NGÔI SAO ĐÊM NHẤP NHÁY ---
  Widget _buildMoonStars(double scale, double t) {
    return SizedBox(
      width: 100 * scale,
      height: 100 * scale,
      child: Stack(
        children: List.generate(4, (i) {
          final angles = [0.4, 1.8, 3.4, 5.1];
          final distances = [40.0, 36.0, 42.0, 38.0];
          final blink = 0.3 + 0.7 * math.sin(t * math.pi * 4 + i * 1.5).abs();
          final x = 50 * scale + math.cos(angles[i]) * distances[i] * scale;
          final y = 50 * scale + math.sin(angles[i]) * distances[i] * scale;

          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: blink,
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFFFDE68A),
                size: (10 + (i % 2) * 4) * scale,
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- ĐÁM MÂY BỒNG BỀNH 3D (PUFFY CLOUD) ---
  Widget _buildPuffyCloud(double scale, double pulse, {bool isStorm = false}) {
    final floatY = math.sin(pulse * math.pi) * 3.5 * scale;
    return Transform.translate(
      offset: Offset(0, floatY),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isStorm
                  ? const Color(0xFF1E1B4B).withOpacity(0.4)
                  : Colors.black.withOpacity(0.18),
              blurRadius: 14 * scale,
              offset: Offset(0, 7 * scale),
            ),
          ],
        ),
        child: Icon(
          Icons.cloud_rounded,
          size: 78 * scale,
          color: isStorm
              ? const Color(0xFFCBD5E1)
              : Colors.white.withOpacity(0.98),
        ),
      ),
    );
  }

  // --- GIỌT MƯA RƠI CHÉO MƯỢT MÀ ---
  List<Widget> _buildRainDrops(double scale, double t, {bool isHeavy = false}) {
    final count = isHeavy ? 9 : 6;
    return List.generate(count, (i) {
      final progress = (t * (isHeavy ? 2.4 : 1.7) + i * (1.0 / count)) % 1.0;
      final x = widget.size * (0.16 + (i / count) * 0.70);
      final y = widget.size * (0.50 + progress * 0.45);
      final alpha = (math.sin(progress * math.pi) * 0.9).clamp(0.0, 1.0);

      return Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: alpha,
          child: Transform.rotate(
            angle: -0.26,
            child: Container(
              width: (isHeavy ? 2.8 : 2.2) * scale,
              height: (isHeavy ? 15.0 : 12.0) * scale,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    isHeavy ? const Color(0xFF93C5FD) : Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      );
    });
  }

  // --- TIA CHỚP CHÂN THẬT (LIGHTNING) ---
  Widget _buildLightning(double scale, double flash) {
    final isStrike = (flash > 0.15 && flash < 0.28) || (flash > 0.75 && flash < 0.88);
    if (!isStrike) return const SizedBox.shrink();

    return Transform.rotate(
      angle: -0.1,
      child: Icon(
        Icons.bolt_rounded,
        size: 38 * scale,
        color: const Color(0xFFFDE047),
        shadows: [
          Shadow(
            color: const Color(0xFFF59E0B),
            blurRadius: 16 * scale,
          ),
          Shadow(
            color: Colors.white,
            blurRadius: 8 * scale,
          ),
        ],
      ),
    );
  }

  // --- BÔNG TUYẾT XOAY BAY LƯỢN (SNOW) ---
  List<Widget> _buildSnowFlakes(double scale, double t) {
    return List.generate(7, (i) {
      final progress = (t * 1.1 + i * 0.15) % 1.0;
      final wobble = math.sin(progress * math.pi * 3 + i) * 6 * scale;
      final x = widget.size * (0.15 + (i / 7) * 0.70) + wobble;
      final y = widget.size * (0.48 + progress * 0.44);

      return Positioned(
        left: x,
        top: y,
        child: Transform.rotate(
          angle: progress * math.pi * 2,
          child: Icon(
            Icons.ac_unit_rounded,
            size: (9 + (i % 3) * 3) * scale,
            color: Colors.white.withOpacity(0.88),
          ),
        ),
      );
    });
  }

  // --- SƯƠNG MÙ BỒNG BỀNH (FOG) ---
  List<Widget> _buildFogLayers(double scale, double t) {
    return List.generate(3, (i) {
      final drift = math.sin(t * math.pi * 2 + i * 1.5) * 8 * scale;
      return Positioned(
        left: widget.size * 0.12 + drift,
        bottom: widget.size * (0.12 + i * 0.12),
        child: Container(
          width: widget.size * 0.82,
          height: 7 * scale,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45 - i * 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }
}

class _SunRaysPainter extends CustomPainter {
  final double scale;
  _SunRaysPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.65)
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    const rayCount = 8;
    final r1 = 34.0 * scale;
    final r2 = 44.0 * scale;

    for (var i = 0; i < rayCount; i++) {
      final angle = i * math.pi * 2 / rayCount;
      final p1 = center + Offset(math.cos(angle) * r1, math.sin(angle) * r1);
      final p2 = center + Offset(math.cos(angle) * r2, math.sin(angle) * r2);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter oldDelegate) => false;
}
