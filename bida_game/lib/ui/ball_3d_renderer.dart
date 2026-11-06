import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Quản lý hướng xoay 3D (3D Orientation) của quả bi trong không gian thế giới
/// Sử dụng 3 vector trực giao (ux, uy, uz) và công thức quay Rodrigues
class Ball3DOrientation {
  double uxx = 1.0, uxy = 0.0, uxz = 0.0;
  double uyx = 0.0, uyy = 1.0, uyz = 0.0;
  double uzx = 0.0, uzy = 0.0, uzz = 1.0;

  Ball3DOrientation({double initialAngle = 0.0}) {
    if (initialAngle != 0.0) {
      spinZ(initialAngle);
    }
  }

  void reset({double angle = 0.0}) {
    uxx = 1.0; uxy = 0.0; uxz = 0.0;
    uyx = 0.0; uyy = 1.0; uyz = 0.0;
    uzx = 0.0; uzy = 0.0; uzz = 1.0;
    if (angle != 0.0) {
      spinZ(angle);
    }
  }

  bool get isValid =>
      !uxx.isNaN && !uxy.isNaN && !uxz.isNaN &&
      !uyx.isNaN && !uyy.isNaN && !uyz.isNaN &&
      !uzx.isNaN && !uzy.isNaN && !uzz.isNaN;

  /// Lăn bi 3D theo vector dịch chuyển (dx, dy) trên mặt bàn nỉ
  void roll(double dx, double dy, double radius) {
    if (radius <= 0 || dx.isNaN || dy.isNaN || dx.isInfinite || dy.isInfinite) return;
    if (!isValid) reset();

    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.0001 || dist.isNaN || dist.isInfinite) return;

    // Giới hạn an toàn khoảng cách lăn trong 1 frame tránh tràn góc xoay khi chuyển app
    final safeDist = math.min(dist, radius * 8.0);

    // Góc quay: quãng đường lăn / bán kính
    final theta = safeDist / radius;

    // Trục quay 3D vuông góc với hướng di chuyển trong mặt phẳng XY:
    // Hướng di chuyển u = (dx/dist, dy/dist, 0)
    // Trục quay = (-dy/dist, dx/dist, 0)
    final ax = -dy / dist;
    final ay = dx / dist;

    _rotateAroundUnitAxis(ax, ay, 0.0, theta);
  }

  /// Xoay quanh trục thẳng đứng Z (áp-phê)
  void spinZ(double angle) {
    if (angle.isNaN || angle.isInfinite || angle.abs() < 0.0001) return;
    if (!isValid) reset();
    _rotateAroundUnitAxis(0.0, 0.0, 1.0, angle);
  }

  void _rotateAroundUnitAxis(double ax, double ay, double az, double theta) {
    final c = math.cos(theta);
    final s = math.sin(theta);
    final oneMinusC = 1.0 - c;

    final r00 = c + ax * ax * oneMinusC;
    final r01 = ax * ay * oneMinusC - az * s;
    final r02 = ax * az * oneMinusC + ay * s;

    final r10 = ay * ax * oneMinusC + az * s;
    final r11 = c + ay * ay * oneMinusC;
    final r12 = ay * az * oneMinusC - ax * s;

    final r20 = az * ax * oneMinusC - ay * s;
    final r21 = az * ay * oneMinusC + ax * s;
    final r22 = c + az * az * oneMinusC;

    final nUxx = r00 * uxx + r01 * uxy + r02 * uxz;
    final nUxy = r10 * uxx + r11 * uxy + r12 * uxz;
    final nUxz = r20 * uxx + r21 * uxy + r22 * uxz;

    final nUyx = r00 * uyx + r01 * uyy + r02 * uyz;
    final nUyy = r10 * uyx + r11 * uyy + r12 * uyz;
    final nUyz = r20 * uyx + r21 * uyy + r22 * uyz;

    final nUzx = r00 * uzx + r01 * uzy + r02 * uzz;
    final nUzy = r10 * uzx + r11 * uzy + r12 * uzz;
    final nUzz = r20 * uzx + r21 * uzy + r22 * uzz;

    uxx = nUxx; uxy = nUxy; uxz = nUxz;
    uyx = nUyx; uyy = nUyy; uyz = nUyz;
    uzx = nUzx; uzy = nUzy; uzz = nUzz;

    // Chuẩn hóa trực giao Gram-Schmidt
    final lenX = math.sqrt(uxx * uxx + uxy * uxy + uxz * uxz);
    if (lenX > 0) {
      uxx /= lenX; uxy /= lenX; uxz /= lenX;
    }
    final dotXY = uxx * uyx + uxy * uyy + uxz * uyz;
    uyx -= dotXY * uxx;
    uyy -= dotXY * uxy;
    uyz -= dotXY * uxz;
    final lenY = math.sqrt(uyx * uyx + uyy * uyy + uyz * uyz);
    if (lenY > 0) {
      uyx /= lenY; uyy /= lenY; uyz /= lenY;
    }
    uzx = uxy * uyz - uxz * uyy;
    uzy = uxz * uyx - uxx * uyz;
    uzz = uxx * uyy - uxy * uyx;
  }
}

/// Renderer vẽ bi bida 2.5D chân thực:
/// - Lăn 3D thực tế (3D Sphere Rolling): Số và sọc lăn tự nhiên đa chiều khi bi di chuyển
/// - Bi cái Aramith Pro Cup 6 chấm đỏ lăn và xoáy 3D
/// - Bóng đổ mặt bàn mềm (Ambient Drop Shadow)
/// - Bo cong thể tích hình cầu 3D (Spherical Shading & Rim Darkening)
/// - Đốm lóa sáng phản chiếu đèn trần (Glossy Specular Highlights)
class Ball3DRenderer {
  // Bảng màu chuẩn quốc tế giải đấu (Aramith Tournament Phenolic Resin)
  // Màu sắc sâu, độ bão hòa cao và tương phản ISO chuẩn nhiếp ảnh thi đấu
  static const Map<int, Color> ballColors = {
    1: Color(0xFFF6A900), // Vàng Amber thi đấu
    2: Color(0xFF0B52B0), // Xanh dương Cobalt hoàng gia
    3: Color(0xFFD31828), // Đỏ Scarlet thắm
    4: Color(0xFF5A187F), // Tím Hoàng gia sâu
    5: Color(0xFFE85400), // Cam Tangerine rực rỡ
    6: Color(0xFF0C6B37), // Xanh lá British Racing đậm
    7: Color(0xFF6E1225), // Nâu đỏ hạt dẻ / Rượu vang Burgundy
    8: Color(0xFF131416), // Đen Pitch Black carbon
    9: Color(0xFFF6A900), // Vàng sọc
    10: Color(0xFF0B52B0), // Xanh dương sọc
    11: Color(0xFFD31828), // Đỏ sọc
    12: Color(0xFF5A187F), // Tím sọc
    13: Color(0xFFE85400), // Cam sọc
    14: Color(0xFF0C6B37), // Xanh lá sọc
    15: Color(0xFF6E1225), // Nâu đỏ sọc
  };

  // Màu trắng ngà Phenolic Resin cao cấp (thay cho trắng giấy xỉn)
  static const Color ivoryResinColor = Color(0xFFFAF9F5);

  // Cache TextPainter cho số 1 đến 15 để tối ưu hiệu năng tối đa (120 FPS)
  static final Map<int, TextPainter> _textPainters = {};

  static TextPainter _getTextPainter(int number, double fontSize) {
    var tp = _textPainters[number];
    if (tp == null || tp.text?.style?.fontSize != fontSize) {
      tp = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: const Color(0xFF141416),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _textPainters[number] = tp;
    }
    return tp;
  }

  /// Dựng hình Quả bi 2.5D với hiệu ứng lăn 3D thực thụ
  static void renderBall({
    required Canvas canvas,
    required double radius,
    required Ball3DOrientation orientation,
    int? ballNumber, // null nếu là bi cái
    double scale = 1.0,
    double opacity = 1.0,
    Offset? cueSpinOffset,
    double pocketDropProgress = 0.0, // 0.0 (trên bàn nỉ) -> 1.0 (chìm sâu vào lòng lỗ)
    double zHeight = 0.0, // Độ cao giả lập trục Z khi bay/nhảy Jump Shot
  }) {
    if (opacity <= 0.001 || scale <= 0.001 || radius <= 0) return;

    // Khi bi nhảy lên cao (Jump Shot): phóng to nhẹ phối cảnh 3D
    final jumpScale = zHeight > 0
        ? 1.0 + (zHeight / (radius * 4.0)).clamp(0.0, 0.32)
        : 1.0;
    final totalScale = scale * jumpScale;

    canvas.save();
    if (totalScale != 1.0) {
      canvas.scale(totalScale, totalScale);
    }

    // ==========================================
    // 1. BÓNG ĐỔ MẶT BÀN NỈ (Ambient Drop Shadow)
    // Đèn trần rọi từ góc trên-trái, bóng đổ nghiêng về dưới-phải
    // Khi bi nhảy cao: Bóng đổ tách rời bên dưới, hơi to ra và mờ dần chân thực
    // ==========================================
    if (pocketDropProgress < 0.50) {
      final shadowAlpha = (1.0 - pocketDropProgress / 0.50).clamp(0.0, 1.0);
      final zOffsetFactor = (zHeight / (radius * 1.6)).clamp(0.0, 3.5);
      final zDim = 1.0 / (1.0 + zOffsetFactor * 0.7);

      final shadowCenter = Offset(
        radius * 0.14,
        radius * 0.18 + (zHeight * 0.65),
      );
      final shadowRect = Rect.fromCenter(
        center: shadowCenter,
        width: radius * (2.12 + zOffsetFactor * 0.4),
        height: radius * (1.88 + zOffsetFactor * 0.3),
      );
      final shadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(0, 0, 0, (0.52 * opacity * shadowAlpha * zDim).clamp(0.0, 1.0)),
            Color.fromRGBO(0, 0, 0, (0.22 * opacity * shadowAlpha * zDim).clamp(0.0, 1.0)),
            const Color(0x00000000),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(shadowRect);
      canvas.drawOval(shadowRect, shadowPaint);
    }

    // ==========================================
    // 2. KHỐI CẦU 3D VÀ HOA VĂN LĂN 3D (Clipped Sphere)
    // Khi bi bay trên không: dịch chuyển quả bi lên cao dọc trục Y ngược chiều trọng lực
    // ==========================================
    canvas.save();
    if (zHeight > 0) {
      canvas.translate(0, -zHeight * 0.75);
    }
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );

    if (ballNumber == null) {
      // ----------------------------------------
      // A. BI CÁI (Cue Ball) - Chuẩn Aramith Pro Cup 6 chấm đỏ lăn 3D
      // ----------------------------------------
      // Thân bi màu trắng ngà Phenolic cao cấp
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()..color = ivoryResinColor,
      );

      // 6 chấm đỏ nằm trên 3 trục trực giao 3D: ±ux, ±uy, ±uz
      final spots = [
        Offset(orientation.uxx, orientation.uxy), orientation.uxz,
        Offset(-orientation.uxx, -orientation.uxy), -orientation.uxz,
        Offset(orientation.uyx, orientation.uyy), orientation.uyz,
        Offset(-orientation.uyx, -orientation.uyy), -orientation.uyz,
        Offset(orientation.uzx, orientation.uzy), orientation.uzz,
        Offset(-orientation.uzx, -orientation.uzy), -orientation.uzz,
      ];

      for (int i = 0; i < spots.length; i += 2) {
        final pos2d = spots[i] as Offset;
        final z = spots[i + 1] as double;
        // Chỉ vẽ những chấm nằm ở nửa cầu phía trước đối diện camera (z > -0.15)
        if (z > -0.15) {
          final spotCenter = Offset(pos2d.dx * radius, pos2d.dy * radius);
          final spotRadius = radius * 0.16 * (0.35 + 0.65 * z.clamp(0.0, 1.0));
          canvas.drawCircle(
            spotCenter,
            spotRadius,
            Paint()..color = const Color(0xFFC61824),
          );
          canvas.drawCircle(
            spotCenter,
            spotRadius * 0.42,
            Paint()..color = const Color(0xFFEA3540),
          );
        }
      }

      // Điểm đánh áp-phê (Spin indicator dot) nếu có
      if (cueSpinOffset != null && (cueSpinOffset.dx.abs() > 0.01 || cueSpinOffset.dy.abs() > 0.01)) {
        final spinDot = Offset(
          cueSpinOffset.dx * radius * 0.55,
          cueSpinOffset.dy * radius * 0.55,
        );
        canvas.drawCircle(
          spinDot,
          radius * 0.12,
          Paint()..color = const Color(0xFF00E5FF),
        );
        canvas.drawCircle(
          spinDot,
          radius * 0.05,
          Paint()..color = Colors.white,
        );
      }
    } else {
      // ----------------------------------------
      // B. BI MỤC TIÊU (Pool Balls 1 đến 15)
      // ----------------------------------------
      final number = ballNumber;
      final isStripe = number >= 9 && number <= 15;
      final mainColor = ballColors[number] ?? const Color(0xFFF6A900);

      if (!isStripe) {
        // Bi màu đặc (Solids 1-8): Toàn bộ nền là màu đặc
        canvas.drawCircle(Offset.zero, radius, Paint()..color = mainColor);
      } else {
        // Bi sọc (Stripes 9-15): Nền trắng ngà, có dải sọc màu chạy quanh xích đạo
        canvas.drawCircle(
          Offset.zero,
          radius,
          Paint()..color = ivoryResinColor,
        );

        // Vẽ dải sọc 3D quanh trục uz
        _draw3DStripe(canvas, radius, orientation, mainColor);
      }

      // Vẽ vòng tròn số trắng (Number Badges) ở 2 cực: +uz và -uz
      _draw3DNumberBadge(canvas, radius, orientation, number, isPositivePole: true);
      _draw3DNumberBadge(canvas, radius, orientation, number, isPositivePole: false);
    }

    // ==========================================
    // 3. ĐỘ CONG KHỐI CẦU 3D & ISO CONTRAST (Spherical Shading & Specular Roll-off)
    // ==========================================
    // Ánh sáng thể tích trực tiếp từ đèn trần (Direct Volumetric Illumination)
    final directLightAlpha = (1.0 - pocketDropProgress * 1.8).clamp(0.0, 1.0);
    if (directLightAlpha > 0.01) {
      final directLightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.28),
          radius: 0.95,
          colors: [
            Color.fromRGBO(255, 255, 255, 0.22 * opacity * directLightAlpha),
            Color.fromRGBO(255, 255, 255, 0.05 * opacity * directLightAlpha),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
      canvas.drawCircle(Offset.zero, radius, directLightPaint);
    }

    // Bóng tối hình cầu tự nhiên (Lambertian Core Shadow)
    final sphereShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.24),
        radius: 1.25,
        colors: [
          const Color(0x00000000),
          const Color(0x00000000),
          Color.fromRGBO(0, 0, 0, 0.25 * opacity),
          Color.fromRGBO(0, 0, 0, 0.85 * opacity),
        ],
        stops: const [0.0, 0.38, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, sphereShadowPaint);

    // Viền tối Fresnel tạo chiều sâu 3D (Fresnel Rim Occlusion)
    final rimDarkeningPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x00000000),
          Color.fromRGBO(0, 0, 0, 0.36 * opacity),
        ],
        stops: const [0.86, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, rimDarkeningPaint);

    // ==========================================
    // 4. ĐỐM SÁNG PHẢN CHIẾU ĐÈN TRẦN (Glossy Specular Highlights)
    // Khi lọt vào bóng tối lòng lỗ bida, đốm chói sáng đèn trần tắt dần
    // ==========================================
    final specFactor = (1.0 - pocketDropProgress * 2.0).clamp(0.0, 1.0);
    if (specFactor > 0.01) {
      final highlightCenter = Offset(-radius * 0.28, -radius * 0.28);

      // Hào quang sáng mềm
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 0.65 * opacity * specFactor),
            Color.fromRGBO(255, 255, 255, 0.15 * opacity * specFactor),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.38));
      canvas.drawCircle(highlightCenter, radius * 0.38, glowPaint);

      // Lõi bóng chói sắc nét (High ISO sharpness)
      final corePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 0.98 * opacity * specFactor),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: highlightCenter, radius: radius * 0.14));
      canvas.drawCircle(highlightCenter, radius * 0.14, corePaint);

      // Điểm phản chiếu phụ (Secondary stadium luminaire fill reflection)
      final fillCenter = Offset(radius * 0.25, radius * 0.25);
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 0.12 * opacity * specFactor),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: fillCenter, radius: radius * 0.20));
      canvas.drawCircle(fillCenter, radius * 0.20, fillPaint);
    }

    // ==========================================
    // 5. BÓNG TỐI HỐ LỖ BIDA (Pocket Cup Depth Occlusion)
    // Khi bi rơi chìm xuống lòng lỗ, bóng tối từ miệng túi da bao trùm
    // Nuốt trọn quả bi đặc vào lòng đen sâu thẳm của lỗ bida tự nhiên thay vì biến mất dần
    // ==========================================
    if (pocketDropProgress > 0.15) {
      final dropRatio = ((pocketDropProgress - 0.15) / 0.85).clamp(0.0, 1.0);
      final cupDarkness = math.pow(dropRatio, 0.90).toDouble();
      final cupShadowPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.15, -0.15),
          radius: 1.05,
          colors: [
            Color.fromRGBO(0, 0, 0, (cupDarkness * 0.90 * opacity).clamp(0.0, 1.0)),
            Color.fromRGBO(0, 0, 0, (cupDarkness * 1.00 * opacity).clamp(0.0, 1.0)),
          ],
          stops: const [0.15, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
      canvas.drawCircle(Offset.zero, radius, cupShadowPaint);
    }

    canvas.restore(); // restore clip
    canvas.restore(); // restore scale
  }

  /// Vẽ dải màu sọc 3D quanh xích đạo của bi số 9-15
  static void _draw3DStripe(
    Canvas canvas,
    double radius,
    Ball3DOrientation ori,
    Color color,
  ) {
    // Góc xoay của vector pháp tuyến uz trong mặt phẳng 2D
    final angle = math.atan2(ori.uzy, ori.uzx);
    final tilt = ori.uzz; // Độ nghiêng cực so với phương nhìn (-1 đến 1)

    canvas.save();
    canvas.rotate(angle);

    // Bề rộng dải sọc xích đạo
    final bandThickness = radius * 1.15;
    // Độ cong của elip viền sọc do góc nghiêng 3D
    final ellipseOffset = radius * 0.45 * tilt;

    final stripePath = Path()
      ..moveTo(-bandThickness * 0.5 + ellipseOffset, -radius * 1.05)
      ..lineTo(bandThickness * 0.5 + ellipseOffset, -radius * 1.05)
      ..lineTo(bandThickness * 0.5 - ellipseOffset, radius * 1.05)
      ..lineTo(-bandThickness * 0.5 - ellipseOffset, radius * 1.05)
      ..close();

    canvas.drawPath(stripePath, Paint()..color = color);
    canvas.restore();
  }

  /// Vẽ vòng tròn số trắng có độ bẹt phối cảnh elip 3D và chữ số quay theo hướng lăn
  static void _draw3DNumberBadge(
    Canvas canvas,
    double radius,
    Ball3DOrientation ori,
    int number, {
    required bool isPositivePole,
  }) {
    final sign = isPositivePole ? 1.0 : -1.0;
    final px = ori.uzx * sign;
    final py = ori.uzy * sign;
    final pz = ori.uzz * sign;

    // Nếu điểm cực nằm ở nửa cầu phía sau (pz < -0.15) thì không nhìn thấy
    if (pz < -0.15) return;

    final center = Offset(px * radius, py * radius);
    final badgeRadius = radius * 0.42;

    // Góc hướng từ tâm bi ra điểm cực
    final distFromCenter = math.sqrt(px * px + py * py);
    final radialAngle = distFromCenter > 0.001 ? math.atan2(py, px) : 0.0;

    // Góc nghiêng của số do hướng xoay ux, uy của quả bi
    final numAngle = math.atan2(ori.uxy * sign, ori.uxx * sign);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Biến đổi elip theo phối cảnh hình cầu (khi lăn ra mép sẽ dẹp lại)
    if (distFromCenter > 0.01) {
      canvas.rotate(radialAngle);
      // Nén dẹp theo hướng bán kính dựa vào pz = cos(góc nhìn)
      final compression = pz.clamp(0.08, 1.0);
      canvas.scale(compression, 1.0);
      canvas.rotate(-radialAngle);
    }

    // Xoay số theo hướng quay cục bộ
    canvas.rotate(numAngle);

    // Vẽ vòng tròn trắng ngà của số
    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()..color = ivoryResinColor,
    );
    // Viền khảm số âm tinh tế (Subtle engraved badge rim)
    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Vẽ số ở tâm vòng tròn trắng
    final fontSize = number >= 10 ? badgeRadius * 0.95 : badgeRadius * 1.15;
    final tp = _getTextPainter(number, fontSize);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }
}
