import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/bus_data.dart';
import '../../core/viewport_scaler.dart';
import 'kawaii_25d_renderer.dart';

class FlyingPetArc {
  final String id;
  final PetColor color;
  final Offset start;
  final Offset end;
  final double progress; // 0.0 -> 1.0 (380ms)

  const FlyingPetArc({
    required this.id,
    required this.color,
    required this.start,
    required this.end,
    required this.progress,
  });

  Offset get currentPosition {
    // Nội suy tuyến tính X và Y kết hợp đỉnh cong Parabol
    final currentX = start.dx + (end.dx - start.dx) * progress;
    final currentY = start.dy + (end.dy - start.dy) * progress;
    // Độ cao uốn cong Parabol (cực đại ở giữa cung bay)
    final arcHeight = -120.0 * math.sin(progress * math.pi);
    return Offset(currentX, currentY + arcHeight);
  }
}

class BusStationPainter extends CustomPainter {
  final ViewportScaler scaler;
  final BusData? activeBus;
  final BusData? nextBus;
  final List<HoldingDockSlot> holdingDock;
  final int score;
  final int currentLevel;
  final List<FlyingPetArc> flyingPets;
  final GameSkinTheme skin;
  final int winStreak;

  BusStationPainter({
    required this.scaler,
    required this.activeBus,
    required this.nextBus,
    required this.holdingDock,
    required this.score,
    required this.currentLevel,
    this.flyingPets = const [],
    this.skin = GameSkinTheme.kawaiiPets,
    this.winStreak = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawParkBackgroundAndRoad(canvas, size);
    _drawNextBusQueue(canvas);
    _drawActiveBus(canvas);
    _drawTopScoreHUD(canvas);
    _drawHoldingDockBench(canvas);
    _drawFlyingPetsParabola(canvas);
  }

  /// 1. Nền công viên Gradient và Đường Vòng Xuyến Hairpin Loop 2.5D ở Zone A
  void _drawParkBackgroundAndRoad(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final parkPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF91DD62),
          Color(0xFF67BF46),
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, parkPaint);

    final rect = scaler.zoneARect;

    // Đồi cỏ nhấp nhô nhẹ tạo chiều sâu diorama
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.left + rect.width * 0.35, rect.top + 26),
        width: rect.width * 0.75,
        height: 60,
      ),
      Paint()..color = const Color(0xFF80D24E),
    );

    // ==========================================
    // VẼ ĐƯỜNG VÒNG XUYẾN HAIRPIN (U-TURN LOOP) 2.5D
    // ==========================================
    final double loopRight = rect.right + 10.0;
    final double loopLeft = rect.left + 22.0;
    final double upperRoadY = rect.top + rect.height * 0.32;
    final double lowerRoadY = rect.top + rect.height * 0.76;
    final double loopRadius = (lowerRoadY - upperRoadY) / 2;
    final double loopCenterY = (upperRoadY + lowerRoadY) / 2;
    final double loopCenterX = loopLeft + loopRadius;

    // A. Lề đường bê tông ngoài (Curb / Sidewalk)
    final curbPath = Path()
      ..moveTo(loopRight, upperRoadY - 24)
      ..lineTo(loopCenterX, upperRoadY - 24)
      ..arcToPoint(
        Offset(loopCenterX, lowerRoadY + 24),
        radius: Radius.circular(loopRadius + 24),
        clockwise: false,
      )
      ..lineTo(loopRight, lowerRoadY + 24)
      ..lineTo(loopRight, lowerRoadY - 14)
      ..lineTo(loopCenterX, lowerRoadY - 14)
      ..arcToPoint(
        Offset(loopCenterX, upperRoadY + 14),
        radius: Radius.circular(loopRadius - 14),
        clockwise: true,
      )
      ..lineTo(loopRight, upperRoadY + 14)
      ..close();

    // Bóng đổ lề đường
    canvas.drawPath(
      curbPath.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(curbPath, Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawPath(
      curbPath,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // B. Mặt đường nhựa xám đậm (Asphalt Track)
    final roadPath = Path()
      ..moveTo(loopRight, upperRoadY - 18)
      ..lineTo(loopCenterX, upperRoadY - 18)
      ..arcToPoint(
        Offset(loopCenterX, lowerRoadY + 18),
        radius: Radius.circular(loopRadius + 18),
        clockwise: false,
      )
      ..lineTo(loopRight, lowerRoadY + 18)
      ..lineTo(loopRight, lowerRoadY - 10)
      ..lineTo(loopCenterX, lowerRoadY - 10)
      ..arcToPoint(
        Offset(loopCenterX, upperRoadY + 10),
        radius: Radius.circular(loopRadius - 10),
        clockwise: true,
      )
      ..lineTo(loopRight, upperRoadY + 10)
      ..close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF37474F), Color(0xFF455A64)],
        ).createShader(rect),
    );

    // C. Vạch kẻ đường vàng/trắng đứt nét ở tâm cua vòng lặp
    final dashPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final dashPath = Path()
      ..moveTo(loopRight, upperRoadY - 4)
      ..lineTo(loopCenterX, upperRoadY - 4)
      ..arcToPoint(
        Offset(loopCenterX, lowerRoadY + 4),
        radius: Radius.circular(loopRadius + 4),
        clockwise: false,
      )
      ..lineTo(loopRight, lowerRoadY + 4);

    // Vẽ vạch đứt nét
    final dashMetrics = dashPath.computeMetrics();
    for (final metric in dashMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = math.min(14.0, metric.length - distance);
        final segment = metric.extractPath(distance, distance + len);
        canvas.drawPath(segment, dashPaint);
        distance += 14.0 + 12.0; // chiều dài vạch + khoảng trống
      }
    }

    // D. Cây xanh diorama 3D hình cầu bông xốp xung quanh đường
    _draw3DParkTree(canvas, Offset(rect.left + 22, rect.top + 28), 16);
    _draw3DParkTree(canvas, Offset(rect.left + 54, rect.top + 20), 12);
    _draw3DParkTree(canvas, Offset(rect.right - 24, rect.top + 34), 14);
    _draw3DParkTree(canvas, Offset(loopCenterX - 6, loopCenterY + 1), 13);

    // E. Cột đèn đường công viên
    _drawStreetLamp(canvas, Offset(rect.left + 14, rect.top + rect.height * 0.44));
  }

  void _draw3DParkTree(Canvas canvas, Offset center, double radius) {
    // Bóng cây trên cỏ
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(2, radius * 0.85), width: radius * 2.2, height: radius * 0.7),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    // Thân cây gỗ nhỏ
    final trunk = Rect.fromLTWH(center.dx - radius * 0.18, center.dy, radius * 0.36, radius * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(trunk, const Radius.circular(2)), Paint()..color = const Color(0xFF6D4226));

    // Khối lá 3 tầng hình cầu 3D
    canvas.drawCircle(center + const Offset(0, 3), radius, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF43A047));
    // Mảng sáng highlight trên tán lá
    canvas.drawCircle(
      center + Offset(-radius * 0.28, -radius * 0.28),
      radius * 0.45,
      Paint()..color = const Color(0xFF81C784),
    );
  }

  void _drawStreetLamp(Canvas canvas, Offset base) {
    // Trụ kim loại đèn đường
    final polePaint = Paint()..color = const Color(0xFF455A64)..strokeWidth = 2.2;
    canvas.drawLine(base, base + const Offset(0, -22), polePaint);
    canvas.drawLine(base + const Offset(0, -22), base + const Offset(6, -24), polePaint);
    // Đầu đèn vàng phát sáng
    canvas.drawCircle(base + const Offset(6, -24), 3.5, Paint()..color = const Color(0xFFFFEE58));
    canvas.drawCircle(
      base + const Offset(6, -24),
      6.0,
      Paint()
        ..color = const Color(0xFFFFEE58).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  /// 2. Vẽ Xe Buýt Đang Đỗ (Active Bus) theo phối cảnh 2.5D Isometric Toy Bus
  void _drawActiveBus(Canvas canvas) {
    if (activeBus == null) return;

    final bus = activeBus!;
    final rect = scaler.zoneARect;

    // Tọa độ xe buýt trên nhánh dưới của đường cua
    final double busWidth = math.min(rect.width * 0.48, 172.0);
    final double busHeight = math.min(rect.height * 0.46, 72.0);
    final double busLeft = rect.left + rect.width * 0.18;
    final double busTop = rect.top + rect.height * 0.50;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

    // 1. Bóng đổ gầm xe 3D
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 6, busRect.bottom - 4, busWidth - 8, 12),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Thân xe 2.5D có góc nghiêng phối cảnh:
    // A. Mặt sườn xe (Main Body Chassis)
    const Radius r = Radius.circular(12);
    final RRect chassis3D = RRect.fromRectAndRadius(busRect.shift(const Offset(0, 6)), r);
    canvas.drawRRect(chassis3D, Paint()..color = bus.isRainbow ? const Color(0xFF4A148C) : bus.color.darkColor);

    final RRect chassisMain = RRect.fromRectAndRadius(busRect, r);
    if (bus.isRainbow) {
      canvas.drawRRect(
        chassisMain,
        Paint()
          ..shader = const LinearGradient(
            colors: [
              Color(0xFFFF5252),
              Color(0xFFFF9800),
              Color(0xFFFFEB3B),
              Color(0xFF4CAF50),
              Color(0xFF29B6F6),
              Color(0xFFAB47BC),
            ],
          ).createShader(busRect),
      );
    } else {
      canvas.drawRRect(
        chassisMain,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bus.color.topGradientStart, bus.color.topGradientEnd],
          ).createShader(busRect),
      );
    }

    // B. Nóc xe vát cạnh bóng bẩy (3D Roof Bevel)
    final Path roofPath = Path()
      ..moveTo(busLeft + 10, busTop + 3)
      ..lineTo(busRect.right - 10, busTop + 3)
      ..lineTo(busRect.right - 14, busTop + 10)
      ..lineTo(busLeft + 14, busTop + 10)
      ..close();
    canvas.drawPath(
      roofPath,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );

    // ĐÔI TAI THÚ CƯNG 3D TRÊN NÓC XE BUÝT (Corgi / Cat Ears)
    _drawBusRoofEars(canvas, Offset(busRect.right - 18, busTop + 3), bus.color);

    // C. 3 Cửa sổ kính lớn xanh biếc (#CDEFFF) có viền nổi
    const int winCount = 3;
    final double winAreaLeft = busLeft + 10;
    final double winAreaW = busWidth - 36;
    final double winW = (winAreaW - 6 * (winCount - 1)) / winCount;
    final double winH = busHeight * 0.44;
    final double winY = busTop + 12;

    for (int i = 0; i < winCount; i++) {
      final wRect = Rect.fromLTWH(winAreaLeft + i * (winW + 6), winY, winW, winH);
      final wRRect = RRect.fromRectAndRadius(wRect, const Radius.circular(6));

      // Kính xanh biếc
      canvas.drawRRect(wRRect, Paint()..color = const Color(0xFFD9F4FF));
      canvas.drawRRect(
        wRRect,
        Paint()
          ..color = const Color(0xFF81D4FA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Vệt sáng chéo trên kính
      final Path sheen = Path()
        ..moveTo(wRect.left + 3, wRect.bottom - 2)
        ..lineTo(wRect.left + 8, wRect.top + 2)
        ..lineTo(wRect.left + 12, wRect.top + 2)
        ..lineTo(wRect.left + 7, wRect.bottom - 2)
        ..close();
      canvas.drawPath(sheen, Paint()..color = Colors.white.withValues(alpha: 0.45));

      // Nếu ô ghế này đã có khách ngồi -> vẽ đầu bé thú cưng nhô lên đáng yêu
      if (i < bus.currentPassengers) {
        _drawWindowPetHead(
          canvas,
          Offset(wRect.center.dx, wRect.bottom - 4),
          winW * 0.36,
          bus.isRainbow ? PetColor.values[i % PetColor.values.length] : bus.color,
        );
      }
    }

    // D. Đèn pha đôi vàng rực rỡ phía đầu xe
    final Offset lightCenter = Offset(busRect.right - 4, busRect.bottom - 16);
    // Tia sáng đèn pha
    canvas.drawOval(
      Rect.fromCenter(center: lightCenter + const Offset(10, 0), width: 22, height: 12),
      Paint()
        ..color = const Color(0xFFFFEE58).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(lightCenter, 4.5, Paint()..color = const Color(0xFFFFEE58));
    canvas.drawCircle(lightCenter, 2.0, Paint()..color = Colors.white);

    // E. Bánh xe lốp cao su đen + mâm bạc thể thao
    _drawWheelWithSilverRim(canvas, Offset(busLeft + 24, busRect.bottom + 2), 8.5);
    _drawWheelWithSilverRim(canvas, Offset(busRect.right - 26, busRect.bottom + 2), 8.5);

    // F. Biển hiệu xe buýt nổi trên nóc: "Corgi Bus 3/4"
    final signRect = Rect.fromCenter(
      center: Offset(busRect.center.dx, busTop - 6),
      width: busWidth * 0.72,
      height: 18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect.shift(const Offset(0, 2)), const Radius.circular(9)),
      Paint()..color = const Color(0xFF3B2314),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(9)),
      Paint()..color = const Color(0xFFFFD84D),
    );
    final signText = TextSpan(
      text: '${bus.name} ${bus.currentPassengers}/${bus.capacity}',
      style: const TextStyle(
        color: Color(0xFF3B2314),
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
    final signPainter = TextPainter(text: signText, textDirection: TextDirection.ltr)..layout();
    signPainter.paint(
      canvas,
      Offset(signRect.center.dx - signPainter.width / 2, signRect.center.dy - signPainter.height / 2),
    );
  }

  /// 3. Vẽ Xe Chờ (Next Bus) đang xếp hàng ở nhánh trên của đường cua
  void _drawNextBusQueue(Canvas canvas) {
    if (nextBus == null) return;

    final bus = nextBus!;
    final rect = scaler.zoneARect;

    // Nằm ở nhánh trên đường cua, hướng chếch bên phải
    final double busWidth = 78.0;
    final double busHeight = math.min(rect.height * 0.38, 54.0);
    final double busLeft = rect.right - busWidth - 14.0;
    final double busTop = rect.top + rect.height * 0.22;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

    // Bóng đổ gầm
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 4)), const Radius.circular(9)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Thân xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 3)), const Radius.circular(9)),
      Paint()..color = bus.color.darkColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect, const Radius.circular(9)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bus.color.topGradientStart, bus.color.topGradientEnd],
        ).createShader(busRect),
    );

    // 2 cửa sổ kính
    for (int i = 0; i < 2; i++) {
      final wRect = Rect.fromLTWH(busLeft + 8 + i * 32, busTop + 7, 26, busHeight * 0.42);
      canvas.drawRRect(RRect.fromRectAndRadius(wRect, const Radius.circular(4)), Paint()..color = const Color(0xFFDDF5FF));
    }

    // Biển hiệu "NEXT"
    final pillRect = Rect.fromCenter(center: Offset(busRect.center.dx, busTop - 4), width: 56, height: 13);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(7)), Paint()..color = const Color(0xFF2B1D14));
    final nextText = TextPainter(
      text: TextSpan(
        text: 'NEXT: ${bus.color.displayName}',
        style: const TextStyle(color: Color(0xFFFFD84D), fontSize: 8.0, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nextText.paint(canvas, Offset(pillRect.center.dx - nextText.width / 2, pillRect.center.dy - nextText.height / 2));

    // Đôi tai mèo 3D trên nóc xe chờ
    _drawBusRoofEars(canvas, Offset(busLeft + 14, busTop + 2), bus.color);

    // Bánh xe
    _drawWheelWithSilverRim(canvas, Offset(busLeft + 16, busRect.bottom + 1), 6.5);
    _drawWheelWithSilverRim(canvas, Offset(busRect.right - 16, busRect.bottom + 1), 6.5);
  }

  void _drawBusRoofEars(Canvas canvas, Offset pos, PetColor color) {
    for (final sign in [-1.0, 1.0]) {
      final earCenter = Offset(pos.dx + sign * 10, pos.dy - 6);
      final earPath = Path()
        ..moveTo(earCenter.dx - 6, pos.dy)
        ..lineTo(earCenter.dx, earCenter.dy - 7)
        ..lineTo(earCenter.dx + 6, pos.dy)
        ..close();
      canvas.drawPath(earPath, Paint()..color = color.topGradientStart);
      canvas.drawPath(
        earPath,
        Paint()
          ..color = color.darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Lòng tai hồng
      final inner = Path()
        ..moveTo(earCenter.dx - 3, pos.dy)
        ..lineTo(earCenter.dx, earCenter.dy - 4)
        ..lineTo(earCenter.dx + 3, pos.dy)
        ..close();
      canvas.drawPath(inner, Paint()..color = color.cheekColor);
    }
  }

  void _drawWheelWithSilverRim(Canvas canvas, Offset center, double radius) {
    // Bóng bánh xe
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, radius * 0.8), width: radius * 2.2, height: radius * 0.6),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    // Lốp đen
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF212121));
    // Mâm bạc sáng
    canvas.drawCircle(center, radius * 0.58, Paint()..color = const Color(0xFFECEFF1));
    canvas.drawCircle(center, radius * 0.22, Paint()..color = const Color(0xFF546E7A));
  }

  void _drawWindowPetHead(Canvas canvas, Offset center, double radius, PetColor color) {
    // Tai thú cưng nhô lên
    canvas.drawCircle(center + Offset(-radius * 0.65, -radius * 0.72), radius * 0.38, Paint()..color = color.topGradientStart);
    canvas.drawCircle(center + Offset(radius * 0.65, -radius * 0.72), radius * 0.38, Paint()..color = color.topGradientStart);

    // Đầu thú tròn
    canvas.drawCircle(center, radius, Paint()..color = color.topGradientEnd);

    // Má hồng
    canvas.drawCircle(center + Offset(-radius * 0.5, radius * 0.15), radius * 0.22, Paint()..color = color.cheekColor);
    canvas.drawCircle(center + Offset(radius * 0.5, radius * 0.15), radius * 0.22, Paint()..color = color.cheekColor);

    // Mắt long lanh
    final eyePaint = Paint()..color = const Color(0xFF1F1A17);
    canvas.drawCircle(center + Offset(-radius * 0.36, -radius * 0.12), radius * 0.18, eyePaint);
    canvas.drawCircle(center + Offset(radius * 0.36, -radius * 0.12), radius * 0.18, eyePaint);
    canvas.drawCircle(center + Offset(-radius * 0.42, -radius * 0.18), radius * 0.07, Paint()..color = Colors.white);
    canvas.drawCircle(center + Offset(radius * 0.30, -radius * 0.18), radius * 0.07, Paint()..color = Colors.white);
  }

  /// 4. HUD Trên Cùng: Biển gỗ treo dây "Level 48" + Lửa Streak x3 + Huy hiệu Tiền 3D & Cài đặt
  void _drawTopScoreHUD(Canvas canvas) {
    final rect = scaler.zoneARect;

    // ==========================================
    // A. BIỂN GỖ TREO 2 DÂY THỪNG: "Level 48"
    // ==========================================
    final double boardLeft = rect.left + 14.0;
    final double boardTop = rect.top + 8.0;
    const double boardW = 76.0;
    const double boardH = 34.0;
    final boardRect = Rect.fromLTWH(boardLeft, boardTop, boardW, boardH);

    // 2 dây thừng treo lên mép trên màn hình
    final ropePaint = Paint()
      ..color = const Color(0xFF6D4226)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(boardLeft + 16, rect.top - 4), Offset(boardLeft + 16, boardTop), ropePaint);
    canvas.drawLine(Offset(boardLeft + boardW - 16, rect.top - 4), Offset(boardLeft + boardW - 16, boardTop), ropePaint);

    // Khối biển gỗ 2.5D caramen
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 3)), const Radius.circular(8)),
      Paint()..color = const Color(0xFF5A3317),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD49B6A), Color(0xFFB37447)],
        ).createShader(boardRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.deflate(1.2), const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFFE8B88A).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final lvlText = TextSpan(
      children: [
        const TextSpan(
          text: 'Level\n',
          style: TextStyle(
            color: Color(0xFF4A2810),
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        TextSpan(
          text: currentLevel == 0 ? 'FTUE' : '$currentLevel',
          style: const TextStyle(
            color: Color(0xFF3B1E08),
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
    final lvlPainter = TextPainter(
      text: lvlText,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: boardW, maxWidth: boardW);
    lvlPainter.paint(canvas, Offset(boardLeft, boardTop + 2));

    // ==========================================
    // B. NGỌN LỬA CHUỖI THẮNG "Streak x3"
    // ==========================================
    final streakCenter = Offset(rect.left + rect.width * 0.44, rect.top + 22.0);
    final streakPill = Rect.fromCenter(center: streakCenter, width: 84, height: 26);

    canvas.drawRRect(
      RRect.fromRectAndRadius(streakPill.shift(const Offset(0, 2)), const Radius.circular(13)),
      Paint()..color = Colors.black26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(streakPill, const Radius.circular(13)),
      Paint()..color = const Color(0xDD21292E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(streakPill, const Radius.circular(13)),
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final flameText = TextSpan(
      children: [
        const TextSpan(text: '🔥 ', style: TextStyle(fontSize: 12)),
        TextSpan(
          text: 'Streak x${math.max(1, winStreak)}',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
    final flamePainter = TextPainter(text: flameText, textDirection: TextDirection.ltr)..layout();
    flamePainter.paint(
      canvas,
      Offset(streakCenter.dx - flamePainter.width / 2, streakCenter.dy - flamePainter.height / 2),
    );

    // ==========================================
    // C. HUY HIỆU XU VÀNG & NGỌC XANH & CÀI ĐẶT Ở GÓC PHẢI
    // ==========================================
    final double rightEdge = rect.right - 10.0;

    // 1. Cài đặt / Cúp vàng
    final settingsCenter = Offset(rightEdge - 16, rect.top + 20);
    canvas.drawCircle(settingsCenter + const Offset(0, 2), 15, Paint()..color = Colors.black26);
    canvas.drawCircle(settingsCenter, 15, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(
      settingsCenter,
      15,
      Paint()
        ..color = const Color(0xFFFFD84D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final trophyPainter = TextPainter(
      text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    trophyPainter.paint(canvas, settingsCenter - Offset(trophyPainter.width / 2, trophyPainter.height / 2));

    // 2. Viên Ngọc Xanh (Diamonds)
    final gemPill = Rect.fromLTWH(settingsCenter.dx - 92, rect.top + 7, 70, 26);
    _drawCurrencyPill(canvas, gemPill, '💎', '120', const Color(0xFF29B6F6));

    // 3. Viên Xu Vàng (Coins)
    final coinPill = Rect.fromLTWH(gemPill.left - 78, rect.top + 7, 72, 26);
    _drawCurrencyPill(canvas, coinPill, '🟡', '$score', const Color(0xFFFFD54F));
  }

  void _drawCurrencyPill(Canvas canvas, Rect pillRect, String icon, String value, Color accentColor) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect.shift(const Offset(0, 2)), const Radius.circular(13)),
      Paint()..color = Colors.black26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(13)),
      Paint()..color = const Color(0xEE1E282D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(13)),
      Paint()
        ..color = accentColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final iconPainter = TextPainter(text: TextSpan(text: icon, style: const TextStyle(fontSize: 12)), textDirection: TextDirection.ltr)..layout();
    iconPainter.paint(canvas, Offset(pillRect.left + 6, pillRect.center.dy - iconPainter.height / 2));

    final valPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: accentColor, fontSize: 11.0, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valPainter.paint(canvas, Offset(pillRect.left + 24, pillRect.center.dy - valPainter.height / 2));
  }

  /// 5. Ghế Chờ Holding Dock Bằng Gỗ Công Viên 2.5D Chuẩn Hình Mẫu
  void _drawHoldingDockBench(Canvas canvas) {
    if (scaler.dockSlotRects.isEmpty) return;

    final double benchLeft = scaler.dockSlotRects.first.left - 12;
    final double benchRight = scaler.dockSlotRects.last.right + 12;
    final double benchWidth = benchRight - benchLeft;
    final Rect seatBandRect = Rect.fromLTWH(
      benchLeft,
      scaler.dockSlotRects.first.top - 4,
      benchWidth,
      scaler.dockSlotRects.first.height + 8,
    );

    // 1. Bóng đổ mềm của ghế công viên xuống mặt cỏ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(benchLeft + 4, seatBandRect.bottom + 4, benchWidth - 8, 8),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2. Chân ghế sắt đen uốn cong cổ điển
    final Paint ironLegPaint = Paint()..color = const Color(0xFF263238);
    for (final legX in [benchLeft + 16, benchRight - 24]) {
      final Rect legRect = Rect.fromLTWH(legX, seatBandRect.bottom - 2, 8, 12);
      canvas.drawRRect(RRect.fromRectAndRadius(legRect, const Radius.circular(3)), ironLegPaint);
    }

    // 3. Tựa lưng gỗ công viên (Backrest) có khắc nhãn "Holding Dock"
    final Rect backrestPlank = Rect.fromLTWH(benchLeft + 4, seatBandRect.top - 14, benchWidth - 8, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank.shift(const Offset(0, 2)), const Radius.circular(5)),
      Paint()..color = const Color(0xFF5A3317),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD49B6A), Color(0xFF9E633A)],
        ).createShader(backrestPlank),
    );

    final int slotCount = scaler.dockSlotRects.length;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: slotCount > 5 ? 'Holding Dock (VIP)' : 'Holding Dock',
        style: const TextStyle(
          color: Color(0xFFFFF8E1),
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(backrestPlank.center.dx - labelPainter.width / 2, backrestPlank.center.dy - labelPainter.height / 2),
    );

    // 4. Mặt ghế gỗ nan caramen 2.5D
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect.shift(const Offset(0, 4)), const Radius.circular(10)),
      Paint()..color = const Color(0xFF6D4226),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB37447), Color(0xFF8D532B)],
        ).createShader(seatBandRect),
    );

    // 5. Vẽ từng vị trí ghế ngồi & thú cưng ngồi thư giãn
    for (int i = 0; i < scaler.dockSlotRects.length; i++) {
      final slotRect = scaler.dockSlotRects[i];
      final slot = (i < holdingDock.length) ? holdingDock[i] : null;
      final isVip = i >= 5 || (slot != null && slot.isVip);

      final Color cushionColor = isVip ? const Color(0xFFFFD84D) : const Color(0xFF4A2810);
      final Color borderColor = isVip ? const Color(0xFFB87D0E) : const Color(0xFF6B3A18);

      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(7)),
        Paint()..color = cushionColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(7)),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      if (slot != null && slot.isLocked) {
        final lockPaint = Paint()
          ..color = Colors.white60
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(slotRect.center, 5, lockPaint);
      } else if (slot != null && slot.petColor != null) {
        // Bé thú cưng 2.5D ngồi trên ghế chờ với tai nhô cao
        final double side = math.min(slotRect.width, slotRect.height) - 4.0;
        final Rect petRect = Rect.fromCenter(center: slotRect.center, width: side, height: side);
        Kawaii25DRenderer.drawBlock(canvas, petRect, slot.petColor!, skin: skin, animateIdle: false);
      } else if (isVip) {
        final vipPainter = TextPainter(
          text: const TextSpan(
            text: 'VIP',
            style: TextStyle(color: Color(0xFF9E4105), fontSize: 9.0, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        vipPainter.paint(
          canvas,
          Offset(slotRect.center.dx - vipPainter.width / 2, slotRect.center.dy - vipPainter.height / 2),
        );
      }
    }
  }

  /// 6. Diễn hoạt ảnh thú cưng bật nhảy theo đường cong Parabol/Bezier (380ms)
  void _drawFlyingPetsParabola(Canvas canvas) {
    for (final pet in flyingPets) {
      final pos = pet.currentPosition;
      final t = pet.progress;

      // Hạt sao lấp lánh xoay quanh thú cưng đang bay
      final sparkOffset1 = Offset(math.cos(t * 12.0) * 14.0, math.sin(t * 12.0) * 14.0);
      final sparkOffset2 = Offset(math.cos(t * 12.0 + math.pi) * 11.0, math.sin(t * 12.0 + math.pi) * 11.0);
      canvas.drawCircle(
        pos + sparkOffset1,
        2.5,
        Paint()..color = const Color(0xFFFFD84D).withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        pos + sparkOffset2,
        2.0,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );

      // Vệt sáng motion trail phía sau
      canvas.drawCircle(
        pos,
        18,
        Paint()
          ..color = pet.color.lightColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      final double rotation = math.sin(t * math.pi) * (pet.end.dx >= pet.start.dx ? 0.32 : -0.32);
      final double popScale = 1.0 + 0.22 * math.sin(t * math.pi);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);
      canvas.scale(popScale, popScale);

      final Rect petRect = Rect.fromCenter(center: Offset.zero, width: 26, height: 26);
      Kawaii25DRenderer.drawBlock(canvas, petRect, pet.color, skin: skin, animateIdle: false);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BusStationPainter oldDelegate) => true;
}
