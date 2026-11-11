import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// Bộ dựng đồ họa Toy 2.5D thương mại (Hỗ trợ 4 bộ Skin + Ticker 60fps thở & chớp mắt tự nhiên)
class Kawaii25DRenderer {
  const Kawaii25DRenderer._();

  /// Vẽ 1 ô khối 2.5D theo Skin đang trang bị, kết hợp nhịp thở và chớp mắt từ Ticker 60fps
  static void drawBlock(
    Canvas canvas,
    Rect cellRect,
    PetColor color, {
    GameSkinTheme skin = GameSkinTheme.kawaiiPets,
    double elapsedSec = 0.0,
    int seed = 0,
    bool animateIdle = true,
  }) {
    if (!animateIdle || elapsedSec == 0.0) {
      _drawBySkin(canvas, cellRect, color, skin, elapsedSec: elapsedSec, blinkOpenness: 1.0);
      return;
    }

    // Nhịp thở phập phồng mượt mà theo thời gian (góc lệch pha theo từng ô seed)
    final double breathWave = math.sin(elapsedSec * 2.8 + seed * 0.65);
    final double scaleX = 1.0 - 0.012 * breathWave;
    final double scaleY = 1.0 + 0.018 * breathWave;

    // Nhịp chớp mắt tự nhiên mỗi ~3.8 giây (thời gian nhắm mắt ~140ms)
    final double cycle = (elapsedSec + seed * 0.73) % 3.8;
    double blinkOpenness = 1.0;
    if (cycle < 0.14) {
      final double t = cycle / 0.14; // 0 -> 1
      blinkOpenness = (1.0 - math.sin(t * math.pi)).clamp(0.08, 1.0);
    }

    canvas.save();
    final Offset pivot = Offset(cellRect.center.dx, cellRect.bottom - 2);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-pivot.dx, -pivot.dy);

    _drawBySkin(
      canvas,
      cellRect,
      color,
      skin,
      elapsedSec: elapsedSec,
      blinkOpenness: blinkOpenness,
    );

    canvas.restore();
  }

  static void _drawBySkin(
    Canvas canvas,
    Rect cellRect,
    PetColor color,
    GameSkinTheme skin, {
    required double elapsedSec,
    required double blinkOpenness,
  }) {
    switch (skin) {
      case GameSkinTheme.kawaiiPets:
        drawKawaiiPetBlock(canvas, cellRect, color, blinkOpenness: blinkOpenness);
        break;
      case GameSkinTheme.jellyCandy:
        _drawJellyBlock(canvas, cellRect, color, blinkOpenness: blinkOpenness);
        break;
      case GameSkinTheme.rgbMechanical:
        _drawRgbKeycapBlock(canvas, cellRect, color, elapsedSec: elapsedSec, blinkOpenness: blinkOpenness);
        break;
      case GameSkinTheme.jadeMahjong:
        _drawJadeMahjongBlock(canvas, cellRect, color, blinkOpenness: blinkOpenness);
        break;
    }
  }

  /// Skin 1 (Mặc định): Bộ đồ chơi Thú Cưng Kawaii 2.5D 6 lớp chuẩn Toy Diorama
  static void drawKawaiiPetBlock(
    Canvas canvas,
    Rect cellRect,
    PetColor color, {
    double blinkOpenness = 1.0,
  }) {
    final double cellWidth = cellRect.width;
    const Radius cornerRadius = Radius.circular(8.0);

    // LỚP 1: Drop Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 7)), cornerRadius),
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // LỚP 2: Đế 3D (Extrusion Lip)
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 5)), cornerRadius),
      Paint()..color = color.darkColor,
    );

    // LỚP 3: Thân Khối Chính
    final Rect bodyRect = cellRect.deflate(1.5);
    final RRect bodyRRect = RRect.fromRectAndRadius(bodyRect, cornerRadius);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.topGradientStart, color.topGradientEnd],
        ).createShader(bodyRect),
    );

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = color.lightColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // LỚP 4: Vệt Bóng Kính (Specular Gloss) ở 20% cạnh trên
    final Rect glossRect = Rect.fromLTWH(
      bodyRect.left + bodyRect.width * 0.08,
      bodyRect.top + 2.0,
      bodyRect.width * 0.84,
      bodyRect.height * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, const Radius.circular(5.0)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // LỚP 5: Đôi Tai Nhô Khỏi Khối (3D Ears)
    _drawToy3DEars(canvas, bodyRect, color);

    // LỚP 6: Khuôn Mặt Kawaii (Đặt ở 1/3 dưới của ô gạch)
    _drawKawaiiPetFace(canvas, bodyRect, color, cellWidth, blinkOpenness: blinkOpenness);
  }

  /// Skin 2: Thạch Rau Câu Jelly (Trong suốt bóng bẩy như kẹo mứt)
  static void _drawJellyBlock(
    Canvas canvas,
    Rect cellRect,
    PetColor color, {
    double blinkOpenness = 1.0,
  }) {
    const Radius cornerRadius = Radius.circular(11.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 7)), cornerRadius),
      Paint()
        ..color = color.darkColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 5)), cornerRadius),
      Paint()..color = color.darkColor.withValues(alpha: 0.85),
    );

    final Rect bodyRect = cellRect.deflate(1.5);
    final RRect bodyRRect = RRect.fromRectAndRadius(bodyRect, cornerRadius);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.65),
            color.topGradientStart.withValues(alpha: 0.92),
            color.topGradientEnd.withValues(alpha: 0.96),
          ],
        ).createShader(bodyRect),
    );

    // Bong bóng kẹo lấp lánh
    canvas.drawOval(
      Rect.fromLTWH(bodyRect.left + bodyRect.width * 0.14, bodyRect.top + 3, bodyRect.width * 0.42, bodyRect.height * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    canvas.drawCircle(
      Offset(bodyRect.right - bodyRect.width * 0.22, bodyRect.top + bodyRect.height * 0.22),
      bodyRect.width * 0.055,
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );

    // Viền đường ngọt ngào
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    _drawSimpleKawaiiEyes(canvas, bodyRect, color, cellRect.width, blinkOpenness: blinkOpenness);
  }

  /// Skin 3: Bàn Phím Cơ RGB (Keycap sculpted eSports + Đèn LED RGB chạy màu)
  static void _drawRgbKeycapBlock(
    Canvas canvas,
    Rect cellRect,
    PetColor color, {
    required double elapsedSec,
    double blinkOpenness = 1.0,
  }) {
    final double hue = (elapsedSec * 60 + color.index * 55) % 360.0;
    final Color rgbGlow = HSLColor.fromAHSL(1.0, hue, 0.95, 0.58).toColor();

    // Đèn gầm RGB tỏa sáng bên dưới Keycap
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 5)), const Radius.circular(8)),
      Paint()
        ..color = rgbGlow.withValues(alpha: 0.78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );

    // Đế vát nghiêng Keycap
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 5)), const Radius.circular(7)),
      Paint()..color = const Color(0xFF1A1E24),
    );

    final Rect bodyRect = cellRect.deflate(1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF333942), color.darkColor],
        ).createShader(bodyRect),
    );

    // Mặt lõm keycap trên đỉnh
    final Rect topCap = bodyRect.deflate(bodyRect.width * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(topCap, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.topGradientStart, color.topGradientEnd],
        ).createShader(topCap),
    );

    // Viền LED RGB
    canvas.drawRRect(
      RRect.fromRectAndRadius(topCap, const Radius.circular(5)),
      Paint()
        ..color = rgbGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    _drawSimpleKawaiiEyes(canvas, topCap, color, cellRect.width * 0.85, blinkOpenness: blinkOpenness);
  }

  /// Skin 4: Mạt Chược Ngọc (Quân bài ngà voi bọc đế ngọc bích viền vàng)
  static void _drawJadeMahjongBlock(
    Canvas canvas,
    Rect cellRect,
    PetColor color, {
    double blinkOpenness = 1.0,
  }) {
    const Radius cornerRadius = Radius.circular(7.0);
    // Đổ bóng
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 7)), cornerRadius),
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Đế ngọc bích dày sang trọng
    canvas.drawRRect(
      RRect.fromRectAndRadius(cellRect.shift(const Offset(0, 5)), cornerRadius),
      Paint()..color = color.darkColor,
    );

    // Lớp viền ngọc lưng
    final Rect bodyRect = cellRect.deflate(1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, cornerRadius),
      Paint()..color = color.topGradientEnd,
    );

    // Mặt ngà voi mịn phía trên
    final Rect ivoryRect = Rect.fromLTWH(
      bodyRect.left + 1.5,
      bodyRect.top + 1.0,
      bodyRect.width - 3.0,
      bodyRect.height - 4.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ivoryRect, const Radius.circular(6.0)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF7), Color(0xFFF3EBD9)],
        ).createShader(ivoryRect),
    );

    // Khung chạm khắc màu vàng kim + ký hiệu thú cưng
    final Rect emblemRect = ivoryRect.deflate(ivoryRect.width * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(emblemRect, const Radius.circular(4.0)),
      Paint()
        ..color = color.topGradientEnd
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Huy hiệu thú màu ở tâm
    canvas.drawCircle(emblemRect.center, emblemRect.width * 0.34, Paint()..color = color.topGradientStart.withValues(alpha: 0.25));
    _drawSimpleKawaiiEyes(canvas, ivoryRect, color, cellRect.width * 0.85, blinkOpenness: blinkOpenness);
  }

  static void _drawSimpleKawaiiEyes(
    Canvas canvas,
    Rect rect,
    PetColor color,
    double cellWidth, {
    double blinkOpenness = 1.0,
  }) {
    final double cx = rect.center.dx;
    final double eyeY = rect.center.dy - rect.height * 0.04;
    final double eyeRadius = cellWidth * 0.075;
    final double blinkH = math.max(1.2, eyeRadius * 2 * blinkOpenness);
    final Paint eyePaint = Paint()..color = const Color(0xFF1F1A17);

    for (final sign in [-1.0, 1.0]) {
      final Offset center = Offset(cx + sign * rect.width * 0.21, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: eyeRadius * 2, height: blinkH),
        eyePaint,
      );
      if (blinkOpenness > 0.45) {
        canvas.drawCircle(
          center + Offset(-eyeRadius * 0.35, -eyeRadius * 0.35),
          cellWidth * 0.028,
          Paint()..color = Colors.white,
        );
      }
    }

    // Má hồng nhỏ
    final Paint cheekPaint = Paint()..color = color.cheekColor.withValues(alpha: 0.75);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - rect.width * 0.28, eyeY + rect.height * 0.14), width: rect.width * 0.15, height: rect.height * 0.09),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + rect.width * 0.28, eyeY + rect.height * 0.14), width: rect.width * 0.15, height: rect.height * 0.09),
      cheekPaint,
    );

    // Miệng cười nhỏ
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, eyeY + rect.height * 0.13), width: rect.width * 0.14, height: rect.height * 0.10),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _drawToy3DEars(Canvas canvas, Rect bodyRect, PetColor color) {
    final double w = bodyRect.width;
    final double h = bodyRect.height;
    final double top = bodyRect.top;
    final double cx = bodyRect.center.dx;

    final Paint outerEarPaint = Paint()
      ..color = color.topGradientStart
      ..style = PaintingStyle.fill;
    final Paint earStrokePaint = Paint()
      ..color = color.darkColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.03);
    final Paint innerEarPaint = Paint()..color = color.accentColor;

    switch (color) {
      case PetColor.red:
        for (final sign in [-1.0, 1.0]) {
          final double earCenterX = cx + sign * w * 0.29;
          final Path ear = Path()
            ..moveTo(earCenterX - sign * w * 0.13, top + h * 0.05)
            ..quadraticBezierTo(earCenterX, top - h * 0.24, earCenterX + sign * w * 0.14, top + h * 0.06)
            ..close();
          canvas.drawPath(ear, outerEarPaint);
          canvas.drawPath(ear, earStrokePaint);

          final Path inner = Path()
            ..moveTo(earCenterX - sign * w * 0.06, top + h * 0.03)
            ..quadraticBezierTo(earCenterX, top - h * 0.13, earCenterX + sign * w * 0.07, top + h * 0.04)
            ..close();
          canvas.drawPath(inner, Paint()..color = color.cheekColor);
        }
        break;

      case PetColor.yellow:
        for (final sign in [-1.0, 1.0]) {
          final Path ear = Path()
            ..moveTo(cx + sign * w * 0.15, top + h * 0.03)
            ..lineTo(cx + sign * w * 0.36, top - h * 0.22)
            ..lineTo(cx + sign * w * 0.42, top + h * 0.06)
            ..close();
          canvas.drawPath(ear, outerEarPaint);
          canvas.drawPath(ear, earStrokePaint);

          final Path inner = Path()
            ..moveTo(cx + sign * w * 0.21, top + h * 0.03)
            ..lineTo(cx + sign * w * 0.34, top - h * 0.13)
            ..lineTo(cx + sign * w * 0.37, top + h * 0.04)
            ..close();
          canvas.drawPath(inner, Paint()..color = color.cheekColor);
        }
        break;

      case PetColor.blue:
        final Path tuft = Path()
          ..moveTo(cx - w * 0.12, top + h * 0.02)
          ..quadraticBezierTo(cx - w * 0.06, top - h * 0.18, cx, top - h * 0.04)
          ..quadraticBezierTo(cx + w * 0.07, top - h * 0.21, cx + w * 0.13, top + h * 0.02)
          ..close();
        canvas.drawPath(tuft, outerEarPaint);
        canvas.drawPath(tuft, earStrokePaint);
        break;

      case PetColor.green:
        for (final sign in [-1.0, 1.0]) {
          final double earX = cx + sign * w * 0.24;
          final Path ear = Path()
            ..moveTo(earX - w * 0.09, top + h * 0.04)
            ..quadraticBezierTo(earX - w * 0.10, top - h * 0.30, earX, top - h * 0.29)
            ..quadraticBezierTo(earX + w * 0.10, top - h * 0.30, earX + w * 0.09, top + h * 0.04)
            ..close();
          canvas.drawPath(ear, outerEarPaint);
          canvas.drawPath(ear, earStrokePaint);

          final Path inner = Path()
            ..moveTo(earX - w * 0.045, top + h * 0.02)
            ..quadraticBezierTo(earX - w * 0.05, top - h * 0.22, earX, top - h * 0.21)
            ..quadraticBezierTo(earX + w * 0.05, top - h * 0.22, earX + w * 0.045, top + h * 0.02)
            ..close();
          canvas.drawPath(inner, innerEarPaint);
        }
        break;

      case PetColor.orange:
        for (final sign in [-1.0, 1.0]) {
          final Path ear = Path()
            ..moveTo(cx + sign * w * 0.14, top + h * 0.04)
            ..lineTo(cx + sign * w * 0.37, top - h * 0.23)
            ..lineTo(cx + sign * w * 0.43, top + h * 0.07)
            ..close();
          canvas.drawPath(ear, outerEarPaint);
          canvas.drawPath(ear, earStrokePaint);

          final Path tip = Path()
            ..moveTo(cx + sign * w * 0.29, top - h * 0.13)
            ..lineTo(cx + sign * w * 0.37, top - h * 0.23)
            ..lineTo(cx + sign * w * 0.40, top - h * 0.09)
            ..close();
          canvas.drawPath(tip, Paint()..color = color.darkColor);

          final Path inner = Path()
            ..moveTo(cx + sign * w * 0.21, top + h * 0.03)
            ..lineTo(cx + sign * w * 0.32, top - h * 0.09)
            ..lineTo(cx + sign * w * 0.36, top + h * 0.04)
            ..close();
          canvas.drawPath(inner, innerEarPaint);
        }
        break;
    }
  }

  static void _drawKawaiiPetFace(
    Canvas canvas,
    Rect bodyRect,
    PetColor color,
    double cellWidth, {
    double blinkOpenness = 1.0,
  }) {
    final double w = bodyRect.width;
    final double h = bodyRect.height;
    final double cx = bodyRect.center.dx;

    final double eyeY = bodyRect.top + h * 0.69;
    final double noseY = bodyRect.top + h * 0.72;
    final double cheekY = bodyRect.top + h * 0.78;
    final double mouthY = bodyRect.top + h * 0.80;

    if (color == PetColor.red) {
      final Path blaze = Path()
        ..moveTo(cx, bodyRect.top + h * 0.36)
        ..quadraticBezierTo(cx - w * 0.11, bodyRect.top + h * 0.56, cx - w * 0.26, bodyRect.top + h * 0.79)
        ..quadraticBezierTo(cx, bodyRect.top + h * 0.96, cx + w * 0.26, bodyRect.top + h * 0.79)
        ..quadraticBezierTo(cx + w * 0.11, bodyRect.top + h * 0.56, cx, bodyRect.top + h * 0.36)
        ..close();
      canvas.drawPath(blaze, Paint()..color = const Color(0xFFFFF8F2));
    } else if (color == PetColor.orange) {
      final Path foxCheeks = Path()
        ..moveTo(bodyRect.left + w * 0.06, bodyRect.top + h * 0.76)
        ..quadraticBezierTo(cx - w * 0.22, bodyRect.top + h * 0.65, cx, bodyRect.top + h * 0.77)
        ..quadraticBezierTo(cx + w * 0.22, bodyRect.top + h * 0.65, bodyRect.right - w * 0.06, bodyRect.top + h * 0.76)
        ..quadraticBezierTo(cx + w * 0.25, bodyRect.bottom - h * 0.04, cx, bodyRect.bottom - h * 0.03)
        ..quadraticBezierTo(cx - w * 0.25, bodyRect.bottom - h * 0.04, bodyRect.left + w * 0.06, bodyRect.top + h * 0.76)
        ..close();
      canvas.drawPath(foxCheeks, Paint()..color = color.accentColor);
    }

    final Paint blushPaint = Paint()
      ..color = (color == PetColor.orange ? const Color(0xFFFFAB91) : color.cheekColor).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.29, cheekY), width: w * 0.17, height: h * 0.10),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.29, cheekY), width: w * 0.17, height: h * 0.10),
      blushPaint,
    );

    // Mắt đen tròn to (radius = cellWidth * 0.08) có chớp mắt tự nhiên + chấm trắng góc trên trái (radius = cellWidth * 0.03)
    final double eyeRadius = cellWidth * 0.08;
    final double glintRadius = cellWidth * 0.03;
    final double eyeOffsetX = w * 0.23;
    final double blinkH = math.max(1.4, eyeRadius * 2 * blinkOpenness);
    final Paint eyePaint = Paint()..color = const Color(0xFF1F1A17);
    final Paint glintPaint = Paint()..color = Colors.white;

    for (final sign in [-1.0, 1.0]) {
      final Offset eyeCenter = Offset(cx + sign * eyeOffsetX, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: eyeRadius * 2, height: blinkH),
        eyePaint,
      );
      if (blinkOpenness > 0.45) {
        canvas.drawCircle(
          eyeCenter + Offset(-eyeRadius * 0.35, -eyeRadius * 0.35),
          glintRadius,
          glintPaint,
        );
      }
    }

    final Paint mouthStroke = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cellWidth * 0.032)
      ..strokeCap = StrokeCap.round;

    switch (color) {
      case PetColor.red:
        final Path nose = Path()
          ..moveTo(cx - w * 0.075, noseY - h * 0.03)
          ..quadraticBezierTo(cx, noseY - h * 0.055, cx + w * 0.075, noseY - h * 0.03)
          ..quadraticBezierTo(cx, noseY + h * 0.06, cx - w * 0.075, noseY - h * 0.03)
          ..close();
        canvas.drawPath(nose, Paint()..color = const Color(0xFF5D2E1E));
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx - w * 0.045, mouthY), width: w * 0.09, height: h * 0.07),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + w * 0.045, mouthY), width: w * 0.09, height: h * 0.07),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        break;

      case PetColor.yellow:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, noseY - h * 0.02), width: w * 0.09, height: h * 0.06),
          Paint()..color = const Color(0xFFFF8A80),
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx - w * 0.055, mouthY), width: w * 0.11, height: h * 0.08),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + w * 0.055, mouthY), width: w * 0.11, height: h * 0.08),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        final Paint whiskerPaint = Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = math.max(0.8, cellWidth * 0.024)
          ..strokeCap = StrokeCap.round;
        for (final sign in [-1.0, 1.0]) {
          canvas.drawLine(
            Offset(cx + sign * w * 0.25, noseY + h * 0.02),
            Offset(cx + sign * w * 0.44, noseY - h * 0.02),
            whiskerPaint,
          );
          canvas.drawLine(
            Offset(cx + sign * w * 0.25, noseY + h * 0.08),
            Offset(cx + sign * w * 0.44, noseY + h * 0.11),
            whiskerPaint,
          );
        }
        break;

      case PetColor.blue:
        final Rect beakRect = Rect.fromCenter(
          center: Offset(cx, noseY + h * 0.04),
          width: w * 0.34,
          height: h * 0.16,
        );
        canvas.drawOval(beakRect, Paint()..color = const Color(0xFFFF9800));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, beakRect.top + beakRect.height * 0.35),
            width: beakRect.width * 0.65,
            height: beakRect.height * 0.32,
          ),
          Paint()..color = const Color(0xFFFFB74D).withValues(alpha: 0.75),
        );
        break;

      case PetColor.green:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, noseY - h * 0.01), width: w * 0.10, height: h * 0.07),
          Paint()..color = const Color(0xFFFFB2C1),
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx - w * 0.045, mouthY), width: w * 0.09, height: h * 0.07),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + w * 0.045, mouthY), width: w * 0.09, height: h * 0.07),
          0,
          math.pi,
          false,
          mouthStroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, mouthY + h * 0.06), width: w * 0.08, height: h * 0.06),
            const Radius.circular(1.5),
          ),
          Paint()..color = Colors.white,
        );
        break;

      case PetColor.orange:
        final Path nose = Path()
          ..moveTo(cx - w * 0.065, noseY - h * 0.02)
          ..quadraticBezierTo(cx, noseY - h * 0.045, cx + w * 0.065, noseY - h * 0.02)
          ..quadraticBezierTo(cx, noseY + h * 0.06, cx - w * 0.065, noseY - h * 0.02)
          ..close();
        canvas.drawPath(nose, Paint()..color = const Color(0xFF3E2723));
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, mouthY), width: w * 0.14, height: h * 0.07),
          0.15,
          math.pi - 0.3,
          false,
          mouthStroke,
        );
        break;
    }
  }
}

