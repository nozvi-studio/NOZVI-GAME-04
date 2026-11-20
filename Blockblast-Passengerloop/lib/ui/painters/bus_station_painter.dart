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
  final BusData? departingBus;
  final double departureProgress;
  final double arrivalProgress;
  final double busBounceProgress;
  final int totalBusesInLevel;
  final int totalDispatchedCount;
  final List<BusData> queuedBuses;
  final List<HoldingDockSlot> holdingDock;
  final int score;
  final int currentLevel;
  final List<FlyingPetArc> flyingPets;
  final GameSkinTheme skin;

  BusStationPainter({
    required this.scaler,
    required this.activeBus,
    required this.nextBus,
    this.departingBus,
    this.departureProgress = 1.0,
    this.arrivalProgress = 1.0,
    this.busBounceProgress = 1.0,
    this.totalBusesInLevel = 1,
    this.totalDispatchedCount = 0,
    this.queuedBuses = const [],
    required this.holdingDock,
    required this.score,
    required this.currentLevel,
    this.flyingPets = const [],
    this.skin = GameSkinTheme.kawaiiPets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawParkBackgroundAndRoad(canvas, size);
    _drawActiveBus(canvas);
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
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.left + rect.width * 0.25, rect.top + 18), width: rect.width * 0.6, height: 42),
      Paint()..color = const Color(0xFF79C750),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.right - rect.width * 0.20, rect.top + 34), width: rect.width * 0.55, height: 46),
      Paint()..color = const Color(0xFF6FBF47),
    );

    // Con đường nhựa xám công viên ở nửa dưới Zone A
    final roadTop = rect.top + rect.height * 0.36;
    final roadPath = Path()
      ..moveTo(rect.left, roadTop)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.5,
        rect.top + rect.height * 0.42,
        rect.right,
        rect.top + rect.height * 0.32,
      )
      ..lineTo(rect.right, rect.bottom - 2)
      ..lineTo(rect.left, rect.bottom - 2)
      ..close();

    // Lề đường sáng nổi
    canvas.drawPath(
      roadPath.shift(const Offset(0, -3)),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF455A64));

    // Đường chân lề dưới
    canvas.drawLine(
      Offset(rect.left, rect.bottom - 2),
      Offset(rect.right, rect.bottom - 2),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF37474F), Color(0xFF455A64)],
        ).createShader(rect),
    );

    // Vạch kẻ đường vàng đứt nét #FFD84D
    final dashPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const double dashWidth = 18.0;
    const double dashGap = 14.0;
    double x = rect.left + 8;
    while (x < rect.right) {
      final yStart = rect.top + rect.height * 0.67 - (x / math.max(1, rect.width)) * 5.0;
      canvas.drawLine(Offset(x, yStart), Offset(x + dashWidth, yStart - 0.5), dashPaint);
      x += dashWidth + dashGap;
    }

    // Cây xanh công viên nhiều lớp lá ở mép trên trái
    _drawParkTree(canvas, Offset(rect.left + 26, rect.top + 26), 15);
    _drawParkTree(canvas, Offset(rect.left + 56, rect.top + 20), 11);
    _drawParkTree(canvas, Offset(rect.right - 26, rect.top + 38), 12);
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

  /// 2. Vẽ Xe Buýt 2.5D Đang Đỗ (Active Bus):
  /// - Thân xe bo tròn có độ dày cạnh dưới
  /// - Biển hiệu nổi trên nóc hiển thị rõ e.g. "Corgi Bus 3/4"
  /// - 3 ô cửa sổ kính xanh nhạt có đầu các bé thú cưng ngồi bên trong
  /// - 2 bánh xe đen có mâm bạc và đèn pha vàng
  void _drawActiveBus(Canvas canvas) {
    if (activeBus == null) return;

    final bus = activeBus!;
    final rect = scaler.zoneARect;
    final double busWidth = math.min(rect.width * 0.50, 186.0);
    final double busHeight = math.min(rect.height * 0.54, 82.0);
    final double busLeft = rect.left + 16.0;
    final double busTop = rect.top + rect.height * 0.37;

    final Rect busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);
    final RRect busRRect = RRect.fromRectAndRadius(busRect, const Radius.circular(13));

    // 1. Bóng đổ gầm xe 3D
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 6, busRect.bottom - 4, busWidth - 8, 12),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Lớp đế 3D sẫm tạo độ dày cạnh dưới thân xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 5)), const Radius.circular(13)),
      Paint()..color = bus.isRainbow ? const Color(0xFF4A148C) : bus.color.darkColor,
    );

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
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bus.color.topGradientStart, bus.color.topGradientEnd],
        ).createShader(busRect);
      canvas.drawRRect(busRRect, bodyPaint);
    }

    // Dải bóng kính nhẹ dọc nóc thân xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 8, busTop + 3, busWidth - 16, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    // Đường chỉ thân xe & cản trước/sau
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 2, busRect.bottom - 10, busWidth - 4, 4),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // Đèn pha vàng rực rỡ phía đầu xe (bên phải xe hướng ra trạm)
    final Offset headlightCenter = Offset(busRect.right - 3, busRect.bottom - 16);
    canvas.drawOval(
      Rect.fromCenter(center: headlightCenter + const Offset(6, 0), width: 16, height: 10),
      Paint()
        ..color = const Color(0xFFFFEE58).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: headlightCenter, width: 7, height: 9),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFEE58),
    );

    // 3 Ô CỬA SỔ KÍNH XANH NHẠT (#CDEFFF)
    const int windowCount = 3;
    final double windowsAreaLeft = busLeft + 10;
    final double windowsAreaWidth = busWidth - 26;
    const double gap = 5.0;
    final double singleWinW = (windowsAreaWidth - gap * (windowCount - 1)) / windowCount;
    final double winTop = busTop + 11;
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

      // Vệt sáng phản chiếu chéo trên mặt kính
      final Path sheen = Path()
        ..moveTo(winRect.left + 3, winRect.top)
        ..lineTo(winRect.left + 10, winRect.top)
        ..lineTo(winRect.left + 3, winRect.bottom)
        ..lineTo(winRect.left - 2, winRect.bottom)
        ..close();
      canvas.drawPath(sheen, Paint()..color = Colors.white.withValues(alpha: 0.35));

      canvas.restore();

      // Viền khung cửa sổ
      canvas.drawRRect(
        winRRect,
        Paint()
          ..color = const Color(0xFF0288D1).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // BIỂN HIỆU NỔI TRÊN NÓC XE: e.g. "Corgi Bus 3/4"
    final double plaqueW = math.max(busWidth * 0.78, 126.0);
    final Rect plaqueRect = Rect.fromLTWH(
      busRect.center.dx - plaqueW / 2,
      busTop - 13,
      plaqueW,
      20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaqueRect.shift(const Offset(0, 2)), const Radius.circular(10)),
      Paint()..color = Colors.black38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaqueRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF2B1D14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plaqueRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFFFD84D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final String labelText = bus.isRainbow
        ? '🌈 Rainbow ${bus.capacityDisplay}'
        : '${bus.name} ${bus.capacityDisplay}';
    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(plaqueRect.center.dx - textPainter.width / 2, plaqueRect.center.dy - textPainter.height / 2),
    );

    // 2 BÁNH XE ĐEN CÓ MÂM BẠC
    _drawWheelWithSilverRim(canvas, Offset(busLeft + 32, busRect.bottom + 1), 10.5);
    _drawWheelWithSilverRim(canvas, Offset(busRect.right - 32, busRect.bottom + 1), 10.5);
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

  /// 3. Vẽ chiếc Xe Chờ (Next Bus) ở góc phải
  void _drawNextBusQueue(Canvas canvas) {
    if (nextBus == null) return;

    final bus = nextBus!;
    final rect = scaler.zoneARect;
    const double busWidth = 82.0;
    final double busHeight = math.min(rect.height * 0.44, 62.0);
    final double busLeft = rect.right - busWidth - 10.0;
    final double busTop = rect.top + rect.height * 0.44;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

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

    // Đèn pha vàng nhỏ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 1, busRect.bottom - 14, 5, 6),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFFEE58),
    );

    // 2 cửa sổ kính xanh nhạt
    for (int i = 0; i < 2; i++) {
      final winRect = Rect.fromLTWH(busLeft + 10 + i * 33, busTop + 8, 28, busHeight * 0.42);
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFFD6F3FF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect, const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFF0288D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Chữ "NEXT"
    final pillRect = Rect.fromLTWH(busLeft + 6, busTop - 10, busWidth - 12, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF2B1D14),
    );
    final textSpan = TextSpan(
      text: 'NEXT: ${bus.color.displayName}',
      style: const TextStyle(
        color: Color(0xFFFFD84D),
        fontSize: 8.5,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pillRect.center.dx - textPainter.width / 2, pillRect.center.dy - textPainter.height / 2),
    );

    // Bánh xe đen mâm bạc
    _drawWheelWithSilverRim(canvas, Offset(busLeft + 18, busRect.bottom + 1), 7.5);
    _drawWheelWithSilverRim(canvas, Offset(busRect.right - 18, busRect.bottom + 1), 7.5);
  }

  /// 4. HUD Điểm số & Màn chơi ở góc trên
  void _drawTopScoreHUD(Canvas canvas) {
    final rect = scaler.zoneARect;
    const double hudWidth = 118.0;
    const double hudHeight = 28.0;
    final hudRect = Rect.fromLTWH(rect.right - hudWidth - 12, rect.top + 8, hudWidth, hudHeight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect.shift(const Offset(0, 2)), const Radius.circular(14)),
      Paint()..color = Colors.black26,
    );
    // Tấm gỗ với gradient vân gỗ ấm áp
    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF2B1D14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFF4A2E1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final trophyPainter = TextPainter(
      text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    trophyPainter.paint(canvas, Offset(hudRect.left + 8, hudRect.center.dy - trophyPainter.height / 2));

    final scorePainter = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(
          color: Color(0xFFFFD84D),
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(canvas, Offset(hudRect.left + 30, hudRect.center.dy - scorePainter.height / 2));

    // Huy hiệu màn chơi ở bên trái (né nút Pause & Hướng dẫn (?))
    final levelRect = Rect.fromLTWH(rect.left + 84, rect.top + 8, 86, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect.shift(const Offset(0, 2)), const Radius.circular(14)),
      Paint()..color = Colors.black26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF2B1D14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFF9E633A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final lvlPainter = TextPainter(
      text: TextSpan(
        text: currentLevel == 0 ? 'Hướng Dẫn' : 'Màn $currentLevel',
        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lvlPainter.paint(
      canvas,
      Offset(levelRect.center.dx - lvlPainter.width / 2, levelRect.center.dy - lvlPainter.height / 2),
    );
  }

  /// 5. Ghế Chờ Holding Dock: Chiếc ghế công viên bằng gỗ có thanh tựa lưng, chân ghế đổ bóng và chia vạch 5 chỗ
  void _drawHoldingDockBench(Canvas canvas) {
    if (scaler.dockSlotRects.isEmpty) return;

    final double benchLeft = scaler.dockSlotRects.first.left - 10;
    final double benchRight = scaler.dockSlotRects.last.right + 10;
    final double benchWidth = benchRight - benchLeft;
    final Rect seatBandRect = Rect.fromLTWH(
      benchLeft,
      scaler.dockSlotRects[startSlot].top - 3,
      benchWidth,
      scaler.dockSlotRects[startSlot].height + 6,
    );

    // 1. Bóng đổ mềm của toàn bộ ghế công viên xuống thảm cỏ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(benchLeft + 3, seatBandRect.bottom + 3, benchWidth - 6, 7),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2. Chân ghế gỗ/sắt đổ bóng hai bên
    final Paint legShadowPaint = Paint()..color = const Color(0xFF3E2723);
    final Paint legWoodPaint = Paint()..color = const Color(0xFF6D4226);
    for (final legX in [benchLeft + 14, benchRight - 22]) {
      final Rect legRect = Rect.fromLTWH(legX, seatBandRect.bottom - 2, 8, 10);
      canvas.drawRRect(RRect.fromRectAndRadius(legRect.shift(const Offset(1, 2)), const Radius.circular(2)), legShadowPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(legRect, const Radius.circular(2)), legWoodPaint);
    }

    // 3. Trụ và Thanh Tựa Lưng (Backrest) phía trên ghế
    for (final postX in [benchLeft + 14, benchRight - 22]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(postX, seatBandRect.top - 14, 8, 18), const Radius.circular(2)),
        Paint()..color = const Color(0xFF6D4226),
      );
    }
    final Rect backrestPlank = Rect.fromLTWH(benchLeft + 4, seatBandRect.top - 13, benchWidth - 8, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank.shift(const Offset(0, 2)), const Radius.circular(5)),
      Paint()..color = const Color(0xFF6D4226),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB37447), Color(0xFF9E633A)],
        ).createShader(backrestPlank),
    );

    final int slotCount = scaler.dockSlotRects.length;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: slotCount > 5 ? 'GHẾ CHỜ ($slotCount CHỖ - VIP)' : 'GHẾ CHỜ (5 CHỖ)',
        style: const TextStyle(
          color: Color(0xFFFFF8E1),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(backrestPlank.center.dx - labelPainter.width / 2, backrestPlank.center.dy - labelPainter.height / 2),
    );

    // 4. Mặt ghế dài 2.5D (#6D4226 đế + #9E633A mặt gỗ)
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect.shift(const Offset(0, 4)), const Radius.circular(11)),
      Paint()..color = const Color(0xFF6D4226),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect, const Radius.circular(11)),
      Paint()..color = const Color(0xFF9E633A),
    );

    // 5. Chia vạch 5 (hoặc 6 VIP) chỗ ngồi rõ ràng và vẽ thú cưng bằng draw25DPetBlock
    for (int i = 0; i < scaler.dockSlotRects.length; i++) {
      final slotRect = scaler.dockSlotRects[i];
      final slot = (i < holdingDock.length) ? holdingDock[i] : null;

      final Color cushionColor = isVip ? const Color(0xFFFFD84D) : const Color(0xFF4A2E1B);
      final Color borderColor = isVip ? const Color(0xFFB87D0E) : const Color(0xFF3B2314);

      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
        Paint()..color = cushionColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(6)),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Vạch chia chỗ ngồi giữa các slot
      if (i < scaler.dockSlotRects.length - 1) {
        final double divX = (slotRect.right + scaler.dockSlotRects[i + 1].left) / 2;
        canvas.drawLine(
          Offset(divX, seatBandRect.top + 4),
          Offset(divX, seatBandRect.bottom - 4),
          Paint()
            ..color = const Color(0xFF6D4226)
            ..strokeWidth = 2.0,
        );
      }

      if (slot != null && slot.isLocked) {
        final lockPaint = Paint()
          ..color = Colors.white60
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(slotRect.center, 5, lockPaint);
      } else if (slot != null && slot.petColor != null) {
        // Vẽ bé thú cưng ngồi trên ghế chờ bằng chuẩn Kawaii25DRenderer theo Skin đang chọn
        final double side = math.min(slotRect.width, slotRect.height) - 6.0;
        final Rect petRect = Rect.fromCenter(center: slotRect.center, width: side, height: side);
        Kawaii25DRenderer.drawBlock(canvas, petRect, slot.petColor!, skin: skin, animateIdle: false);
      }
    }

    // 6. Nhãn phụ bên dưới ghế (e.g. "Holding Dock" chuẩn ảnh mẫu)
    if (subtitleLabel != null) {
      final subPainter = TextPainter(
        text: TextSpan(
          text: subtitleLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            shadows: [
              Shadow(color: Colors.black87, offset: Offset(0, 1.5), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      subPainter.paint(
        canvas,
        Offset(seatBandRect.center.dx - subPainter.width / 2, seatBandRect.bottom + 6),
      );
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
  bool shouldRepaint(covariant BusStationPainter oldDelegate) {
    if (oldDelegate.score != score ||
        oldDelegate.currentLevel != currentLevel ||
        oldDelegate.streak != streak ||
        oldDelegate.coins != coins ||
        oldDelegate.activeBus != activeBus ||
        oldDelegate.nextBus != nextBus ||
        oldDelegate.departingBus != departingBus ||
        oldDelegate.departureProgress != departureProgress ||
        oldDelegate.arrivalProgress != arrivalProgress ||
        oldDelegate.busBounceProgress != busBounceProgress ||
        oldDelegate.totalBusesInLevel != totalBusesInLevel ||
        oldDelegate.totalDispatchedCount != totalDispatchedCount ||
        oldDelegate.queuedBuses != queuedBuses ||
        oldDelegate.skin != skin ||
        oldDelegate.scaler != scaler ||
        oldDelegate.flyingPets != flyingPets ||
        flyingPets.isNotEmpty ||
        departureProgress < 1.0 ||
        arrivalProgress < 1.0 ||
        busBounceProgress < 1.0 ||
        oldDelegate.holdingDock.length != holdingDock.length) {
      return true;
    }
    final occupied = holdingDock.where((s) => s.petColor != null).length;
    if (occupied >= holdingDock.length - 1 && occupied > 0) {
      return true;
    }
    for (int i = 0; i < holdingDock.length; i++) {
      if (oldDelegate.holdingDock[i].petColor != holdingDock[i].petColor ||
          oldDelegate.holdingDock[i].isLocked != holdingDock[i].isLocked) {
        return true;
      }
    }
    return false;
  }
}
