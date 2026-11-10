import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/bus_data.dart';
import '../../core/viewport_scaler.dart';

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

  BusStationPainter({
    required this.scaler,
    required this.activeBus,
    required this.nextBus,
    required this.holdingDock,
    required this.score,
    required this.currentLevel,
    this.flyingPets = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawTopParkRoad(canvas);
    _drawActiveBus(canvas);
    _drawNextBusQueue(canvas);
    _drawTopScoreHUD(canvas);
    _drawHoldingDockBench(canvas);
    _drawFlyingPetsParabola(canvas);
  }

  /// 1. Vẽ con đường cong công viên và cây xanh ở Zone A
  void _drawTopParkRoad(Canvas canvas) {
    final rect = scaler.zoneARect;

    // Nền cỏ xanh công viên
    final grassPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(rect, grassPaint);

    // Con đường nhựa xám uốn cong nhẹ
    final roadPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;

    final roadPath = Path();
    roadPath.moveTo(rect.left, rect.top + rect.height * 0.35);
    roadPath.quadraticBezierTo(
      rect.left + rect.width * 0.5,
      rect.top + rect.height * 0.40,
      rect.right,
      rect.top + rect.height * 0.30,
    );
    roadPath.lineTo(rect.right, rect.bottom);
    roadPath.lineTo(rect.left, rect.bottom);
    roadPath.close();
    canvas.drawPath(roadPath, roadPaint);

    // Vạch kẻ đường đứt nét vàng
    final linePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height * 0.65),
      Offset(rect.right, rect.top + rect.height * 0.60),
      linePaint,
    );

    // Vẽ một vài tán cây xanh nhỏ ở mép trên
    final treePaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(rect.left + 24, rect.top + 20), 16, treePaint);
    canvas.drawCircle(Offset(rect.left + 52, rect.top + 16), 12, treePaint);
  }

  /// 2. Vẽ chiếc Xe Buýt Đang Đỗ (Active Bus) ở trạm với cửa sổ và đầu thú cưng
  void _drawActiveBus(Canvas canvas) {
    if (activeBus == null) return;

    final bus = activeBus!;
    final rect = scaler.zoneARect;
    final busWidth = math.min(rect.width * 0.46, 175.0);
    final busHeight = rect.height * 0.52;
    final busLeft = rect.left + 16.0;
    final busTop = rect.top + rect.height * 0.38;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

    // Đổ bóng xe
    final shadowPaint = Paint()..color = Colors.black26;
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 4)), const Radius.circular(10)),
      shadowPaint,
    );

    // Thân xe buýt (màu theo loài thú cưng hoặc Rainbow nếu là Rainbow Express)
    if (bus.isRainbow) {
      final rainbowPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF1744),
            Color(0xFFFF9100),
            Color(0xFFFFEA00),
            Color(0xFF00E676),
            Color(0xFF2979FF),
            Color(0xFFAA00FF),
          ],
        ).createShader(busRect);
      canvas.drawRRect(RRect.fromRectAndRadius(busRect, const Radius.circular(10)), rainbowPaint);
    } else {
      final bodyPaint = Paint()..color = bus.color.primaryColor;
      canvas.drawRRect(RRect.fromRectAndRadius(busRect, const Radius.circular(10)), bodyPaint);
    }

    // Phần đế xe màu sẫm
    final underPaint = Paint()..color = bus.isRainbow ? const Color(0xFF311B92) : bus.color.darkColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft, busRect.bottom - 6, busWidth, 6),
        const Radius.circular(4),
      ),
      underPaint,
    );

    // Cửa kính xe buýt lớn phía trước & các cửa sổ hông
    final windowPaint = Paint()..color = const Color(0xFFE1F5FE);
    final windowBorder = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final windowRect = Rect.fromLTWH(busLeft + 8, busTop + 6, busWidth - 16, busHeight * 0.45);
    canvas.drawRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(6)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(6)), windowBorder);

    // Vẽ đầu các bé thú cưng đã lên xe đang lấp ló qua cửa sổ!
    final int passengers = bus.currentPassengers;
    final int capacity = bus.capacity;
    final slotWidth = windowRect.width / math.max(1, capacity);

    for (int i = 0; i < passengers; i++) {
      final petColor = (i < bus.passengerPets.length) ? bus.passengerPets[i] : bus.color;
      final headCenter = Offset(windowRect.left + (i + 0.5) * slotWidth, windowRect.bottom - 4);

      // Đầu tròn nhỏ của bé thú
      final headPaint = Paint()..color = petColor.primaryColor;
      canvas.drawCircle(headCenter, 8.5, headPaint);
      // Mắt
      final eyePaint = Paint()..color = Colors.black87;
      canvas.drawCircle(headCenter + const Offset(-3, -2), 1.4, eyePaint);
      canvas.drawCircle(headCenter + const Offset(3, -2), 1.4, eyePaint);
    }

    // Nhãn hiển thị tên và số lượng chỗ: e.g. "Corgi Bus 3/4"
    final pillRect = Rect.fromLTWH(busLeft + 6, busTop - 11, busWidth - 12, 18);
    final pillPaint = Paint()..color = const Color(0xEE212121);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(9)), pillPaint);

    final textSpan = TextSpan(
      text: bus.isRainbow
          ? '🌈 Rainbow ${bus.capacityDisplay}'
          : '${bus.name} ${bus.capacityDisplay}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pillRect.center.dx - textPainter.width / 2, pillRect.center.dy - textPainter.height / 2),
    );

    // 2 Bánh xe buýt đen
    final wheelPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(busLeft + 18, busRect.bottom), 6, wheelPaint);
    canvas.drawCircle(Offset(busRect.right - 18, busRect.bottom), 6, wheelPaint);
  }

  /// 3. Vẽ chiếc Xe Chờ (Next Bus) ở góc phải
  void _drawNextBusQueue(Canvas canvas) {
    if (nextBus == null) return;

    final bus = nextBus!;
    final rect = scaler.zoneARect;
    final busWidth = 72.0;
    final busHeight = rect.height * 0.44;
    final busLeft = rect.right - busWidth + 12.0;
    final busTop = rect.top + rect.height * 0.44;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

    // Thân xe chờ
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect, const Radius.circular(8)),
      Paint()..color = bus.color.primaryColor.withValues(alpha: 0.9),
    );

    // Cửa sổ
    final winRect = Rect.fromLTWH(busLeft + 6, busTop + 6, busWidth - 12, busHeight * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(4)),
      Paint()..color = const Color(0xCCB3E5FC),
    );

    // Chữ "Kế tiếp"
    final textSpan = TextSpan(
      text: 'NEXT: ${bus.color.displayName}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8.5,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(busLeft + 6, busTop - 9));
  }

  /// 4. HUD Điểm số & Màn chơi ở góc trên bên phải
  void _drawTopScoreHUD(Canvas canvas) {
    final rect = scaler.zoneARect;
    final hudWidth = 140.0;
    final hudHeight = 32.0;
    final hudRect = Rect.fromLTWH(rect.right - hudWidth - 14, rect.top + 8, hudWidth, hudHeight);

    // Hộp HUD viên thuốc tròn
    final hudPaint = Paint()..color = const Color(0xEE1E1E1E);
    canvas.drawRRect(RRect.fromRectAndRadius(hudRect, const Radius.circular(16)), hudPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(RRect.fromRectAndRadius(hudRect, const Radius.circular(16)), borderPaint);

    // Biểu tượng Cúp Vàng
    final trophyPainter = TextPainter(
      text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    trophyPainter.layout();
    trophyPainter.paint(canvas, Offset(hudRect.left + 8, hudRect.center.dy - trophyPainter.height / 2));

    // Điểm số
    final scoreSpan = TextSpan(
      text: '$score',
      style: const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final scorePainter = TextPainter(text: scoreSpan, textDirection: TextDirection.ltr);
    scorePainter.layout();
    scorePainter.paint(canvas, Offset(hudRect.left + 34, hudRect.center.dy - scorePainter.height / 2));

    // Huy hiệu màn chơi ở bên trái
    final levelRect = Rect.fromLTWH(rect.left + 14, rect.top + 8, 86, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(levelRect, const Radius.circular(13)),
      Paint()..color = const Color(0xDD212121),
    );
    final lvlSpan = TextSpan(
      text: currentLevel == 0 ? 'Màn FTUE' : 'Màn $currentLevel',
      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
    );
    final lvlPainter = TextPainter(text: lvlSpan, textDirection: TextDirection.ltr);
    lvlPainter.layout();
    lvlPainter.paint(
      canvas,
      Offset(levelRect.center.dx - lvlPainter.width / 2, levelRect.center.dy - lvlPainter.height / 2),
    );
  }

  /// 5. Vẽ chiếc Ghế Dài Công Viên "Holding Dock" với các chỗ ngồi ở Zone B
  void _drawHoldingDockBench(Canvas canvas) {
    if (scaler.dockSlotRects.isEmpty) return;
    final rect = scaler.zoneBRect;

    // Mặt gỗ ghế dài công viên
    final benchRect = Rect.fromLTWH(
      scaler.dockSlotRects.first.left - 8,
      scaler.dockSlotRects.first.top - 4,
      (scaler.dockSlotRects.last.right - scaler.dockSlotRects.first.left) + 16,
      scaler.dockSlotRects.first.height + 8,
    );

    // Đổ bóng ghế
    canvas.drawRRect(
      RRect.fromRectAndRadius(benchRect.shift(const Offset(0, 3)), const Radius.circular(12)),
      Paint()..color = Colors.black26,
    );

    // Thanh gỗ ghế dài
    canvas.drawRRect(
      RRect.fromRectAndRadius(benchRect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF6D4C41),
    );

    final int slotCount = scaler.dockSlotRects.length;
    // Nhãn "Holding Dock" phía trên ghế
    final labelSpan = TextSpan(
      text: slotCount > 5 ? 'HOLDING DOCK ($slotCount CHỖ - VIP)' : 'HOLDING DOCK (5 CHỖ)',
      style: const TextStyle(
        color: Color(0xFFFFD180),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
    final labelPainter = TextPainter(text: labelSpan, textDirection: TextDirection.ltr);
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(benchRect.center.dx - labelPainter.width / 2, rect.top + 1));

    // Vẽ từng ghế ngồi và thú cưng đang ngồi đợi
    for (int i = 0; i < scaler.dockSlotRects.length; i++) {
      final slotRect = scaler.dockSlotRects[i];
      final slot = (i < holdingDock.length) ? holdingDock[i] : null;
      final isVip = i >= 5 || (slot != null && slot.isVip);

      // Nền đệm ghế ngồi: Vàng kim rực rỡ nếu là ghế thứ 6+ VIP, Nâu nếu ghế thường
      final cushionColor = isVip ? const Color(0xFFFFD54F) : const Color(0xFF3E2723);
      final borderCol = isVip ? const Color(0xFFFF8F00) : const Color(0xFF4E342E);
      final borderW = isVip ? 2.0 : 1.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
        Paint()..color = cushionColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
        Paint()
          ..color = borderCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderW,
      );

      if (slot != null && slot.isLocked) {
        // Ghế bị khóa
        final lockPaint = Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(slotRect.center, 5, lockPaint);
      } else if (slot != null && slot.petColor != null) {
        // Thú cưng đang ngồi trên ghế
        _drawDockedPet(canvas, slotRect.center, slot.petColor!);
      } else if (isVip) {
        // Ghế VIP còn trống: Vẽ huy hiệu chữ VIP nhỏ
        final vipSpan = const TextSpan(
          text: 'VIP',
          style: TextStyle(
            color: Color(0xFFE65100),
            fontSize: 9.0,
            fontWeight: FontWeight.w900,
          ),
        );
        final vipPainter = TextPainter(text: vipSpan, textDirection: TextDirection.ltr)..layout();
        vipPainter.paint(
          canvas,
          Offset(slotRect.center.dx - vipPainter.width / 2, slotRect.center.dy - vipPainter.height / 2),
        );
      }
    }
  }

  void _drawDockedPet(Canvas canvas, Offset center, PetColor color) {
    // Bé thú cưng nhỏ xinh ngồi trên ghế
    final petPaint = Paint()..color = color.primaryColor;
    canvas.drawCircle(center, 12.0, petPaint);

    final darkPaint = Paint()..color = color.darkColor;
    canvas.drawCircle(center + const Offset(0, 2), 12.0, Paint()..color = color.darkColor.withValues(alpha: 0.3));

    // Mắt
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(center + const Offset(-4, -2), 1.8, eyePaint);
    canvas.drawCircle(center + const Offset(4, -2), 1.8, eyePaint);
    canvas.drawCircle(center + const Offset(-4 - 0.5, -2 - 0.5), 0.7, Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(4 - 0.5, -2 - 0.5), 0.7, Paint()..color = Colors.white);

    // Mũi nhỏ
    canvas.drawCircle(center + const Offset(0, 2), 1.5, darkPaint);
  }

  /// 6. Diễn hoạt ảnh thú cưng bật nhảy theo đường cong Parabol/Bezier (380ms)
  void _drawFlyingPetsParabola(Canvas canvas) {
    for (final pet in flyingPets) {
      final pos = pet.currentPosition;

      // Vệt sáng motion trail phía sau
      final trailPaint = Paint()
        ..color = pet.color.lightColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 14, trailPaint);

      // Thân bé thú đang bay
      canvas.drawCircle(pos, 11, Paint()..color = pet.color.primaryColor);
      // Mắt
      canvas.drawCircle(pos + const Offset(-3.5, -2), 1.8, Paint()..color = Colors.black);
      canvas.drawCircle(pos + const Offset(3.5, -2), 1.8, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant BusStationPainter oldDelegate) => true;
}

