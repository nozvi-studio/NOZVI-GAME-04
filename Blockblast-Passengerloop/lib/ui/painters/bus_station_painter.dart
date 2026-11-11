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

  BusStationPainter({
    required this.scaler,
    required this.activeBus,
    required this.nextBus,
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
    _drawTopScoreHUD(canvas);
    _drawHoldingDockBench(canvas);
    _drawFlyingPetsParabola(canvas);
  }

  /// 1. Nền công viên Gradient (#88D45E -> #5BB344) toàn màn hình và đường xe buýt Zone A
  void _drawParkBackgroundAndRoad(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final parkPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF88D45E),
          Color(0xFF5BB344),
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, parkPaint);

    // Thảm cỏ đồi nhẹ ở Zone A
    final rect = scaler.zoneARect;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.left + rect.width * 0.25, rect.top + 18), width: rect.width * 0.6, height: 42),
      Paint()..color = const Color(0xFF79C750),
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
        ..color = const Color(0xFF263238)
        ..strokeWidth = 3.0,
    );

    // Vạch kẻ đường vàng đứt nét #FFD84D
    final dashPaint = Paint()
      ..color = const Color(0xFFFFD84D)
      ..strokeWidth = 2.6
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

  void _drawParkTree(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center + const Offset(0, 4), radius, Paint()..color = const Color(0xFF2D8512));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF4BC226));
    canvas.drawCircle(center + Offset(-radius * 0.25, -radius * 0.25), radius * 0.45, Paint()..color = const Color(0xFF81E659));
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

    // Đổ bóng gầm xe trên mặt đường
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 4, busRect.bottom - 2, busWidth - 8, 10),
        const Radius.circular(6),
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

    // Thân xe chính có Gradient
    if (bus.isRainbow) {
      final rainbowPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF6B5B),
            Color(0xFFFF9D42),
            Color(0xFFFFD84D),
            Color(0xFF81E659),
            Color(0xFF4FC3F7),
            Color(0xFFAB47BC),
          ],
        ).createShader(busRect);
      canvas.drawRRect(busRRect, rainbowPaint);
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

    final int passengers = bus.currentPassengers;
    for (int w = 0; w < windowCount; w++) {
      final Rect winRect = Rect.fromLTWH(
        windowsAreaLeft + w * (singleWinW + gap),
        winTop,
        singleWinW,
        winH,
      );
      final RRect winRRect = RRect.fromRectAndRadius(winRect, const Radius.circular(6));

      // Kính xanh nhạt
      canvas.drawRRect(
        winRRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F7FF), Color(0xFFB3E5FC)],
          ).createShader(winRect),
      );

      // Clip cửa sổ để vẽ đầu các bé thú ngồi bên trong
      canvas.save();
      canvas.clipRRect(winRRect);

      // Nếu có hành khách tương ứng (hoặc chia đều nếu capacity > 3)
      for (int pIdx = w; pIdx < passengers; pIdx += windowCount) {
        final PetColor pColor = (pIdx < bus.passengerPets.length) ? bus.passengerPets[pIdx] : bus.color;
        final double xShift = (pIdx >= windowCount) ? 7.0 : 0.0;
        _drawWindowPetHead(
          canvas,
          Offset(winRect.center.dx + xShift * 0.4, winRect.bottom - 5),
          winRect.height * 0.44,
          pColor,
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
        letterSpacing: 0.2,
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
      Rect.fromCenter(center: center + Offset(0, radius * 0.8), width: radius * 2.1, height: radius * 0.55),
      Paint()..color = Colors.black38,
    );
    // Lốp đen
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = const Color(0xFF424242)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Mâm bạc sáng bóng
    canvas.drawCircle(center, radius * 0.56, Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawCircle(center, radius * 0.24, Paint()..color = const Color(0xFF546E7A));
  }

  void _drawWindowPetHead(Canvas canvas, Offset center, double radius, PetColor color) {
    // Tai nhỏ nhô trên đầu
    canvas.drawCircle(center + Offset(-radius * 0.65, -radius * 0.72), radius * 0.36, Paint()..color = color.topGradientStart);
    canvas.drawCircle(center + Offset(radius * 0.65, -radius * 0.72), radius * 0.36, Paint()..color = color.topGradientStart);

    // Đầu thú tròn
    canvas.drawCircle(center, radius, Paint()..color = color.topGradientEnd);

    // Má hồng
    canvas.drawCircle(center + Offset(-radius * 0.5, radius * 0.15), radius * 0.22, Paint()..color = color.cheekColor);
    canvas.drawCircle(center + Offset(radius * 0.5, radius * 0.15), radius * 0.22, Paint()..color = color.cheekColor);

    // Mắt long lanh
    final eyePaint = Paint()..color = const Color(0xFF1F1A17);
    canvas.drawCircle(center + Offset(-radius * 0.36, -radius * 0.12), radius * 0.19, eyePaint);
    canvas.drawCircle(center + Offset(radius * 0.36, -radius * 0.12), radius * 0.19, eyePaint);
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

    // Đế 3D
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 4)), const Radius.circular(10)),
      Paint()..color = bus.color.darkColor,
    );

    // Thân xe chờ Gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect, const Radius.circular(10)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bus.color.topGradientStart, bus.color.topGradientEnd],
        ).createShader(busRect),
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF2B1D14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hudRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFFFFD84D)
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
        ..strokeWidth = 1.4,
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
      scaler.dockSlotRects.first.top - 4,
      benchWidth,
      scaler.dockSlotRects.first.height + 8,
    );

    // 1. Bóng đổ mềm của toàn bộ ghế công viên xuống thảm cỏ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(benchLeft + 4, seatBandRect.bottom + 4, benchWidth - 8, 8),
        const Radius.circular(6),
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
      RRect.fromRectAndRadius(backrestPlank, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
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
      final isVip = i >= 5 || (slot != null && slot.isVip);

      final Color cushionColor = isVip ? const Color(0xFFFFD84D) : const Color(0xFF4A2E1B);
      final Color borderColor = isVip ? const Color(0xFFB87D0E) : const Color(0xFF3B2314);

      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(7)),
        Paint()..color = cushionColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(7)),
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

      // Vệt sáng motion trail phía sau
      canvas.drawCircle(
        pos,
        16,
        Paint()
          ..color = pet.color.lightColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      final Rect petRect = Rect.fromCenter(center: pos, width: 26, height: 26);
      Kawaii25DRenderer.drawBlock(canvas, petRect, pet.color, skin: skin, animateIdle: false);
    }
  }

  @override
  bool shouldRepaint(covariant BusStationPainter oldDelegate) => true;
}
