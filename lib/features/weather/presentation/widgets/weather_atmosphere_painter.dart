import 'dart:math' as math;
import 'package:flutter/material.dart';

/// BỘ VẼ HIỆU ỨNG THỜI TIẾT TOÀN DIỆN (CANVAS ATMOSPHERE PAINTER)
class WeatherAtmospherePainter extends CustomPainter {
  final double progress;
  final int? code;
  final bool isDaytime;

  WeatherAtmospherePainter({
    required this.progress,
    required this.code,
    required this.isDaytime,
  });

  bool get _isRain => const [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code);
  bool get _isStorm => const [95, 96, 99].contains(code);
  bool get _isSnow => const [71, 73, 75, 77, 85, 86].contains(code);
  bool get _isFog => const [45, 48].contains(code);
  bool get _isClear => code == 0 || code == 1 || code == 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (_isClear && isDaytime) {
      _paintSunnyAtmosphere(canvas, size);
    } else if (!isDaytime) {
      _paintNightAtmosphere(canvas, size);
    }

    if (_isRain || _isStorm) {
      _paintRainAndLightning(canvas, size);
    } else if (_isSnow) {
      _paintSnowAtmosphere(canvas, size);
    } else if (_isFog) {
      _paintFogAtmosphere(canvas, size);
    }

    _paintFloatingClouds(canvas, size);
  }

  static final Paint _coronaPaint = Paint();
  static final Paint _sparklePaint = Paint()..color = const Color(0xFFFEF3C7).withOpacity(0.35);
  static final Paint _starPaint = Paint()..color = Colors.white;
  static final Paint _shootPaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  static final Paint _rainPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _ripplePaint = Paint()
    ..color = Colors.white.withOpacity(0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _flashOverlay = Paint()
    ..color = const Color(0xFFFDE047).withOpacity(0.18);
  static final Paint _boltPaint = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeJoin = StrokeJoin.round;
  static final Path _boltPath = Path();
  static final Paint _snowPaint = Paint()..color = Colors.white.withOpacity(0.8);
  static final Paint _fogPaint = Paint()..color = Colors.white.withOpacity(0.16);
  static final Paint _cloudPaint = Paint();
  static final Path _cloudPath = Path();

  void _paintSunnyAtmosphere(Canvas canvas, Size size) {
    final sunCenter = Offset(
      size.width * 0.82 + math.sin(progress * math.pi * 2) * 12,
      size.height * 0.14,
    );

    _coronaPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFFBEB).withOpacity(0.38),
        const Color(0xFFFDE68A).withOpacity(0.18),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: 170));
    canvas.drawCircle(sunCenter, 170, _coronaPaint);

    for (var i = 0; i < 22; i++) {
      final x = (i * 61.0 + math.sin(progress * math.pi * 2 + i) * 18) % size.width;
      final y = (i * 87.0 + progress * 40) % (size.height * 0.7);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.8, _sparklePaint);
    }
  }

  void _paintNightAtmosphere(Canvas canvas, Size size) {
    for (var i = 0; i < 48; i++) {
      final x = (i * 79.0 + (i * 17) % 31) % size.width;
      final y = (i * 47.0 + (i * 23) % 41) % (size.height * 0.75);
      final twinkle = 0.25 + 0.75 * math.sin(progress * math.pi * 6 + i * 2.1).abs();
      _starPaint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.6, _starPaint);
    }

    final shootingProgress = (progress * 2.5) % 1.0;
    if (shootingProgress < 0.35) {
      final t = shootingProgress / 0.35;
      final startX = size.width * (0.2 + t * 0.6);
      final startY = size.height * (0.05 + t * 0.25);
      _shootPaint.shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.85),
        ],
      ).createShader(
        Rect.fromPoints(
          Offset(startX - 50, startY - 25),
          Offset(startX, startY),
        ),
      );
      canvas.drawLine(
        Offset(startX - 50, startY - 25),
        Offset(startX, startY),
        _shootPaint,
      );
    }
  }

  void _paintRainAndLightning(Canvas canvas, Size size) {
    _rainPaint
      ..color = Colors.white.withOpacity(_isStorm ? 0.38 : 0.28)
      ..strokeWidth = _isStorm ? 2.2 : 1.7;

    for (var i = 0; i < 64; i++) {
      final speedFactor = 1.0 + (i % 4) * 0.3;
      final x = (i * 37.0) % (size.width + 50);
      final y = (i * 59.0 + progress * size.height * 1.8 * speedFactor) %
          (size.height + 60);

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 6, y + (_isStorm ? 18 : 13)),
        _rainPaint,
      );

      if (y > size.height - 70 && i % 3 == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x - 6, y + 14),
            width: 14 + (i % 3) * 6,
            height: 4,
          ),
          _ripplePaint,
        );
      }
    }

    if (_isStorm) {
      final flashVal = (progress * 5) % 1.0;
      if (flashVal > 0.82 && flashVal < 0.94) {
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _flashOverlay);

        _boltPath.reset();
        _boltPath.moveTo(size.width * 0.72, size.height * 0.08);
        _boltPath.lineTo(size.width * 0.65, size.height * 0.22);
        _boltPath.lineTo(size.width * 0.70, size.height * 0.21);
        _boltPath.lineTo(size.width * 0.58, size.height * 0.38);
        _boltPath.lineTo(size.width * 0.62, size.height * 0.37);
        _boltPath.lineTo(size.width * 0.52, size.height * 0.52);
        canvas.drawPath(_boltPath, _boltPaint);
      }
    }
  }

  void _paintSnowAtmosphere(Canvas canvas, Size size) {
    for (var i = 0; i < 40; i++) {
      final progressOffset = (progress + i * 0.025) % 1.0;
      final sway = math.sin(progressOffset * math.pi * 4 + i) * 22;
      final x = (i * 47.0 + sway) % size.width;
      final y = (i * 73.0 + progressOffset * size.height * 1.1) % (size.height + 30);
      final radius = 1.8 + (i % 4) * 1.1;

      canvas.drawCircle(Offset(x, y), radius, _snowPaint);
    }
  }

  void _paintFogAtmosphere(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.35 + i * 0.10);
      final drift = math.sin(progress * math.pi * 2 + i * 1.4) * 45;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5 + drift, y),
          width: size.width * 1.1,
          height: 32 + i * 6,
        ),
        _fogPaint,
      );
    }
  }

  void _paintFloatingClouds(Canvas canvas, Size size) {
    _cloudPaint.color = Colors.white.withOpacity(_isStorm ? 0.08 : 0.14);

    final travel = size.width + 280;
    for (var layer = 0; layer < 2; layer++) {
      final direction = layer == 0 ? 1 : -1;
      final scale = layer == 0 ? 1.0 : 1.35;
      final y = size.height * (0.78 + layer * 0.12);

      for (var i = 0; i < 3; i++) {
        final x = ((progress * travel * direction * 0.6 + i * 220 * scale) % travel) -
            140 * scale;
        _cloudPath.reset();
        _cloudPath.addOval(Rect.fromLTWH(x, y, 160 * scale, 52 * scale));
        _cloudPath.addOval(Rect.fromLTWH(x + 32 * scale, y - 28 * scale, 80 * scale, 64 * scale));
        _cloudPath.addOval(Rect.fromLTWH(x + 88 * scale, y - 18 * scale, 95 * scale, 56 * scale));
        canvas.drawPath(_cloudPath, _cloudPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeatherAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.code != code ||
        oldDelegate.isDaytime != isDaytime;
  }
}
