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
  final double elapsedSec;
  final int streak;
  final int coins;

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
    this.elapsedSec = 0.0,
    this.streak = 3,
    this.coins = 2450,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawParkBackgroundAndRoad(canvas, size);
    if (departingBus != null && departureProgress < 1.0) {
      _drawDepartingBus(canvas);
    }
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

    final rect = scaler.zoneARect;

    // Thảm cỏ đồi nhẹ uốn lượn ở Zone A
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.left + rect.width * 0.25, rect.top + 28), width: rect.width * 0.65, height: 50),
      Paint()..color = const Color(0xFF79C750),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.right - rect.width * 0.20, rect.top + 34), width: rect.width * 0.55, height: 46),
      Paint()..color = const Color(0xFF6FBF47),
    );

    // Con đường nhựa xám công viên uốn lượn mềm mại từ góc trên trái sang phải
    final roadPath = Path()
      ..moveTo(rect.left - 10, rect.top + rect.height * 0.20)
      ..cubicTo(
        rect.left + rect.width * 0.25, rect.top + rect.height * 0.28,
        rect.left + rect.width * 0.40, rect.top + rect.height * 0.44,
        rect.left + rect.width * 0.70, rect.top + rect.height * 0.46,
      )
      ..cubicTo(
        rect.left + rect.width * 0.88, rect.top + rect.height * 0.47,
        rect.right, rect.top + rect.height * 0.38,
        rect.right + 20, rect.top + rect.height * 0.32,
      )
      ..lineTo(rect.right + 20, rect.bottom + 2)
      ..lineTo(rect.left - 10, rect.bottom + 2)
      ..close();

    // Lề đường sáng nổi (Curb)
    canvas.drawPath(
      roadPath.shift(const Offset(0, -3.5)),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    // Mặt đường nhựa xám đậm
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF455A64));

    // Đường chân lề dưới
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
      Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 3.0,
    );

    // Vạch kẻ đường vàng đứt nét uốn cong theo con đường #FFD84D
    final dashPaint = Paint()
      ..color = const Color(0xFFFFD84D)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    const double dashWidth = 16.0;
    const double dashGap = 13.0;
    double x = rect.left + 6;
    while (x < rect.right - 8) {
      final normX = (x - rect.left) / math.max(1, rect.width);
      final double yCurve = rect.top + rect.height * (0.64 + 0.08 * math.sin(normX * math.pi * 1.1) - normX * 0.06);
      canvas.drawLine(Offset(x, yCurve), Offset(x + dashWidth, yCurve - 0.6), dashPaint);
      x += dashWidth + dashGap;
    }

    // Biển báo giao thông công viên (Street Signs) chuẩn ảnh mẫu
    _drawStreetSigns(canvas, rect);

    // Cây xanh công viên nhiều lớp lá mềm mại ở các mép
    _drawParkTree(canvas, Offset(rect.left + 18, rect.top + 48), 16);
    _drawParkTree(canvas, Offset(rect.left + 46, rect.top + 40), 12);
    _drawParkTree(canvas, Offset(rect.right - 22, rect.top + 42), 14);
    _drawParkTree(canvas, Offset(rect.right - 46, rect.top + 32), 11);
  }

  /// Vẽ 2 cụm biển báo giao thông:
  /// - Trái: Biển tròn viền đỏ có biểu tượng thú cưng
  /// - Phải: Biển thoi vàng cảnh báo dấu chân 🐾 + biển chỉ hướng xanh dương
  void _drawStreetSigns(Canvas canvas, Rect rect) {
    // 1. Biển báo bên trái
    final double leftSignX = rect.left + 38.0;
    final double leftSignBaseY = rect.top + rect.height * 0.74;
    final double leftSignTopY = leftSignBaseY - 32.0;

    // Cột kim loại màu xám bạc
    canvas.drawLine(
      Offset(leftSignX, leftSignBaseY),
      Offset(leftSignX, leftSignTopY),
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    // Biển tròn
    final Offset signCenter = Offset(leftSignX, leftSignTopY - 10.0);
    canvas.drawCircle(signCenter, 11.0, Paint()..color = Colors.white);
    canvas.drawCircle(
      signCenter,
      11.0,
      Paint()
        ..color = const Color(0xFFD32F2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    // Ký hiệu thú cưng / chú chó màu đỏ bên trong
    final corgiIconPainter = TextPainter(
      text: const TextSpan(
        text: '🐶',
        style: TextStyle(fontSize: 10.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    corgiIconPainter.paint(
      canvas,
      signCenter - Offset(corgiIconPainter.width / 2, corgiIconPainter.height / 2),
    );

    // 2. Biển báo bên phải (Cảnh báo Thú cưng qua đường)
    final double rightSignX = rect.right - 78.0;
    final double rightSignBaseY = rect.top + rect.height * 0.32;
    final double rightSignTopY = rightSignBaseY - 26.0;

    // Cột kim loại
    canvas.drawLine(
      Offset(rightSignX, rightSignBaseY),
      Offset(rightSignX, rightSignTopY),
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Biển hình thoi vàng (Diamond Warning Sign)
    final Offset diamondCenter = Offset(rightSignX, rightSignTopY - 8.0);
    const double diamondSize = 11.0;
    final diamondPath = Path()
      ..moveTo(diamondCenter.dx, diamondCenter.dy - diamondSize)
      ..lineTo(diamondCenter.dx + diamondSize, diamondCenter.dy)
      ..lineTo(diamondCenter.dx, diamondCenter.dy + diamondSize)
      ..lineTo(diamondCenter.dx - diamondSize, diamondCenter.dy)
      ..close();
    canvas.drawPath(diamondPath, Paint()..color = const Color(0xFFFFD600));
    canvas.drawPath(
      diamondPath,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Biểu tượng dấu chân đen 🐾
    final pawSignPainter = TextPainter(
      text: const TextSpan(
        text: '🐾',
        style: TextStyle(fontSize: 9.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pawSignPainter.paint(
      canvas,
      diamondCenter - Offset(pawSignPainter.width / 2, pawSignPainter.height / 2),
    );

    // Biển chỉ hướng xanh dương ngay dưới biển thoi
    final Rect blueSignRect = Rect.fromCenter(
      center: Offset(rightSignX, rightSignTopY + 4.0),
      width: 14.0,
      height: 7.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(blueSignRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF1976D2),
    );
    final arrowPainter = TextPainter(
      text: const TextSpan(
        text: '➜',
        style: TextStyle(color: Colors.white, fontSize: 6.0, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    arrowPainter.paint(
      canvas,
      blueSignRect.center - Offset(arrowPainter.width / 2, arrowPainter.height / 2),
    );
  }

  void _drawParkTree(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center + const Offset(0, 4), radius, Paint()..color = const Color(0xFF2D8512));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF4BC226));
    canvas.drawCircle(center + Offset(-radius * 0.25, -radius * 0.25), radius * 0.45, Paint()..color = const Color(0xFF81E659));
  }

  double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1.0;
    final t = x.clamp(0.0, 1.0);
    return 1.0 + c3 * math.pow(t - 1.0, 3) + c1 * math.pow(t - 1.0, 2);
  }

  /// 2. Vẽ Xe Buýt 2.5D Đang Xuất Bến (Departing Bus với Khói Lốp & Tăng Tốc)
  void _drawDepartingBus(Canvas canvas) {
    if (departingBus == null) return;

    final bus = departingBus!;
    final rect = scaler.zoneARect;
    final double busWidth = math.min(rect.width * 0.50, 186.0);
    final double busHeight = math.min(rect.height * 0.54, 82.0);

    // Gia tốc phóng nhanh về bên phải
    final double departDist = math.pow(departureProgress, 2.2) * (rect.width * 1.15);
    final double depLeft = rect.left + 16.0 + departDist;
    final double depTop = rect.top + rect.height * 0.37;
    final Rect busRect = Rect.fromLTWH(depLeft, depTop, busWidth, busHeight);

    // Diễn hoạt khói lốp (Tire smoke puffs) bốc lên từ bánh sau
    final double rearWheelX = depLeft + 32;
    final double wheelY = busRect.bottom + 1;
    for (int s = 0; s < 4; s++) {
      final double sProg = (departureProgress * 2.0 - s * 0.20).clamp(0.0, 1.0);
      if (sProg > 0.0 && sProg < 1.0) {
        final double smokeX = rearWheelX - sProg * 38.0 - s * 6.0;
        final double smokeY = wheelY - sProg * 16.0 - s * 2.0;
        final double radius = 4.0 + sProg * 11.0;
        final double opacity = (1.0 - sProg) * 0.65;
        canvas.drawCircle(
          Offset(smokeX, smokeY),
          radius,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
    }

    _drawBusAt(
      canvas,
      bus,
      busRect,
      opacity: (1.0 - departureProgress * 0.65).clamp(0.2, 1.0),
    );
  }

  /// 3. Vẽ Xe Buýt 2.5D Đang Đỗ (Active Bus) với Phanh Lún Nhún Lò Xo & Hiệu Ứng Khách Lên Xe
  void _drawActiveBus(Canvas canvas) {
    if (activeBus == null) return;

    final bus = activeBus!;
    final rect = scaler.zoneARect;
    final double busWidth = math.min(rect.width * 0.50, 186.0);
    final double busHeight = math.min(rect.height * 0.54, 82.0);

    // Trượt từ phải vào trạm nếu đang trong hiệu ứng cập bến (Arrival Slide-in)
    double busLeft = rect.left + 16.0;
    if (arrivalProgress < 1.0) {
      final double slideOffset = (1.0 - _easeOutBack(arrivalProgress)) * (rect.width * 0.70);
      busLeft += slideOffset;
    }

    // Nhún lò xo giảm xóc (Suspension Bounce) khi có thú cưng đáp lên xe
    double busTop = rect.top + rect.height * 0.37;
    if (busBounceProgress < 1.0) {
      final double bounce = math.sin(busBounceProgress * math.pi) * 5.5;
      busTop += bounce;
    }

    final Rect busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);
    _drawBusAt(canvas, bus, busRect);

    // Hiệu ứng số lượng hành khách nổi "+1 🐾" khi vừa đón khách
    if (busBounceProgress < 0.85) {
      final double popT = busBounceProgress / 0.85;
      final double popY = busTop - 22.0 - popT * 14.0;
      final double alpha = (1.0 - popT).clamp(0.0, 1.0);
      final textSpan = TextSpan(
        text: '+1 🐾',
        style: TextStyle(
          color: const Color(0xFFFFD84D).withValues(alpha: alpha),
          fontSize: 13.0,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: alpha * 0.7), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(busRect.center.dx - textPainter.width / 2, popY));
    }
  }

  /// Hàm dựng thân xe 2.5D chuẩn đồ chơi diorama với lớp sơn bóng, kính và huy hiệu
  void _drawBusAt(
    Canvas canvas,
    BusData bus,
    Rect busRect, {
    double opacity = 1.0,
  }) {
    final double busLeft = busRect.left;
    final double busTop = busRect.top;
    final double busWidth = busRect.width;
    final double busHeight = busRect.height;
    final RRect busRRect = RRect.fromRectAndRadius(busRect, const Radius.circular(13));

    // Đổ bóng gầm xe trên mặt đường
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 4, busRect.bottom - 2, busWidth - 8, 10),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Lớp đế 3D sẫm tạo độ dày cạnh dưới thân xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 5)), const Radius.circular(13)),
      Paint()..color = (bus.isRainbow ? const Color(0xFF4A148C) : bus.color.darkColor).withValues(alpha: opacity),
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
          colors: [
            bus.color.topGradientStart.withValues(alpha: opacity),
            bus.color.topGradientEnd.withValues(alpha: opacity),
          ],
        ).createShader(busRect);
      canvas.drawRRect(busRRect, bodyPaint);
    }

    // Dải bóng kính nhẹ dọc nóc thân xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 8, busTop + 3, busWidth - 16, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.32 * opacity),
    );

    // Đường chỉ thân xe & cản trước/sau
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 2, busRect.bottom - 10, busWidth - 4, 4),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25 * opacity),
    );

    // Đèn pha vàng rực rỡ phía đầu xe (bên phải xe hướng ra trạm)
    final Offset headlightCenter = Offset(busRect.right - 3, busRect.bottom - 16);
    canvas.drawOval(
      Rect.fromCenter(center: headlightCenter + const Offset(6, 0), width: 16, height: 10),
      Paint()
        ..color = const Color(0xFFFFEE58).withValues(alpha: 0.35 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: headlightCenter, width: 7, height: 9),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFEE58).withValues(alpha: opacity),
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
      canvas.drawPath(sheen, Paint()..color = Colors.white.withValues(alpha: 0.35 * opacity));

      canvas.restore();

      // Viền khung cửa sổ
      canvas.drawRRect(
        winRRect,
        Paint()
          ..color = const Color(0xFF0288D1).withValues(alpha: 0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // BIỂN HIỆU NỔI DẠNG BÓNG NÓI (SPEECH BUBBLE) TRÊN NÓC XE: e.g. "Corgi Bus 3/4"
    final double plaqueW = math.max(busWidth * 0.72, 116.0);
    const double plaqueH = 22.0;
    final Rect plaqueRect = Rect.fromCenter(
      center: Offset(busRect.center.dx, busTop - 13),
      width: plaqueW,
      height: plaqueH,
    );
    final RRect bubbleRRect = RRect.fromRectAndRadius(plaqueRect, const Radius.circular(8));
    final Path bubblePath = Path()
      ..addRRect(bubbleRRect)
      ..moveTo(busRect.center.dx - 6, plaqueRect.bottom)
      ..lineTo(busRect.center.dx, plaqueRect.bottom + 5)
      ..lineTo(busRect.center.dx + 6, plaqueRect.bottom)
      ..close();

    // Bóng đổ nhẹ của biển nóc
    canvas.drawPath(
      bubblePath.shift(const Offset(0, 2)),
      Paint()..color = Colors.black26.withValues(alpha: 0.35 * opacity),
    );
    // Thân biển trắng tinh
    canvas.drawPath(
      bubblePath,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawPath(
      bubblePath,
      Paint()
        ..color = const Color(0xFFD7CCC8).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final String labelText = bus.isRainbow
        ? '🌈 Rainbow ${bus.capacityDisplay}'
        : '${bus.name} Bus ${bus.capacityDisplay}';
    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: const Color(0xFF2B1D14).withValues(alpha: opacity),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(
      canvas,
      Offset(plaqueRect.center.dx - textPainter.width / 2, plaqueRect.center.dy - textPainter.height / 2),
    );

    // BANNER TRẮNG TRÊN THÂN XE PHÍA DƯỚI CỬA SỔ: e.g. "Corgi Express"
    final double bannerW = math.min(busWidth * 0.65, 110.0);
    final Rect bannerRect = Rect.fromCenter(
      center: Offset(busRect.center.dx, busRect.bottom - 17),
      width: bannerW,
      height: 14.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bannerRect.shift(const Offset(0, 1)), const Radius.circular(7)),
      Paint()..color = Colors.black26.withValues(alpha: 0.25 * opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bannerRect, const Radius.circular(7)),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    final bannerSpan = TextSpan(
      text: '${bus.name} Express',
      style: TextStyle(
        color: (bus.isRainbow ? const Color(0xFF6A1B9A) : bus.color.darkColor).withValues(alpha: opacity),
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
    final bannerPainter = TextPainter(text: bannerSpan, textDirection: TextDirection.ltr)..layout();
    bannerPainter.paint(
      canvas,
      Offset(bannerRect.center.dx - bannerPainter.width / 2, bannerRect.center.dy - bannerPainter.height / 2),
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

  /// 3. Vẽ chiếc Xe Chờ (Next Bus) ở góc phải đường uốn lượn
  void _drawNextBusQueue(Canvas canvas) {
    if (nextBus == null) return;

    final bus = nextBus!;
    final rect = scaler.zoneARect;
    const double busWidth = 84.0;
    final double busHeight = math.min(rect.height * 0.44, 62.0);
    final double busLeft = rect.right - busWidth - 8.0;
    final double busTop = rect.top + rect.height * 0.42;

    final busRect = Rect.fromLTWH(busLeft, busTop, busWidth, busHeight);

    // Bóng gầm xe
    canvas.drawRRect(
      RRect.fromRectAndRadius(busRect.shift(const Offset(0, 5)), const Radius.circular(10)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

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

    // Đèn pha vàng
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(busLeft + 2, busRect.bottom - 13, 5, 6),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFFEE58),
    );

    // 2 cửa sổ kính xanh nhạt
    for (int i = 0; i < 2; i++) {
      final winRect = Rect.fromLTWH(busLeft + 10 + i * 34, busTop + 8, 28, busHeight * 0.42);
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

    // BIỂN HIỆU NỔI DẠNG BÓNG NÓI TRÊN NÓC XE CHỜ: e.g. "Cat Bus 0/4"
    final double nextPlaqueW = math.max(busWidth * 0.88, 86.0);
    const double nextPlaqueH = 18.0;
    final Rect nextPlaqueRect = Rect.fromCenter(
      center: Offset(busRect.center.dx, busTop - 11),
      width: nextPlaqueW,
      height: nextPlaqueH,
    );
    final RRect nextBubbleRRect = RRect.fromRectAndRadius(nextPlaqueRect, const Radius.circular(7));
    final Path nextBubblePath = Path()
      ..addRRect(nextBubbleRRect)
      ..moveTo(busRect.center.dx - 4, nextPlaqueRect.bottom)
      ..lineTo(busRect.center.dx, nextPlaqueRect.bottom + 4)
      ..lineTo(busRect.center.dx + 4, nextPlaqueRect.bottom)
      ..close();

    canvas.drawPath(nextBubblePath.shift(const Offset(0, 1.5)), Paint()..color = Colors.black26);
    canvas.drawPath(nextBubblePath, Paint()..color = Colors.white);
    canvas.drawPath(
      nextBubblePath,
      Paint()
        ..color = const Color(0xFFD7CCC8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final String nextLabel = '${bus.name} Bus ${bus.capacityDisplay}';
    final nextSpan = TextSpan(
      text: nextLabel,
      style: const TextStyle(
        color: Color(0xFF2B1D14),
        fontSize: 9.0,
        fontWeight: FontWeight.w900,
      ),
    );
    final nextPainter = TextPainter(text: nextSpan, textDirection: TextDirection.ltr)..layout();
    nextPainter.paint(
      canvas,
      Offset(nextPlaqueRect.center.dx - nextPainter.width / 2, nextPlaqueRect.center.dy - nextPainter.height / 2),
    );

    // Bánh xe đen mâm bạc
    _drawWheelWithSilverRim(canvas, Offset(busLeft + 18, busRect.bottom + 1), 7.5);
    _drawWheelWithSilverRim(canvas, Offset(busRect.right - 18, busRect.bottom + 1), 7.5);
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  /// 4. HUD Điểm số & Màn chơi ở góc trên chuẩn ảnh mẫu
  void _drawTopScoreHUD(Canvas canvas) {
    final rect = scaler.zoneARect;

    // 1. Biển gỗ treo hiển thị Màn chơi (Hanging Wooden Level Sign) ở góc trái
    const double signW = 54.0;
    const double signH = 46.0;
    final double signLeft = rect.left + 8.0;
    final double signTop = rect.top + 8.0;
    final Rect signRect = Rect.fromLTWH(signLeft, signTop, signW, signH);

    // Hai sợi dây thừng nâu treo từ mép trên màn hình
    final ropePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(signLeft + 12, 0), Offset(signLeft + 12, signTop + 3), ropePaint);
    canvas.drawLine(Offset(signRect.right - 12, 0), Offset(signRect.right - 12, signTop + 3), ropePaint);

    // Bóng đổ biển gỗ
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect.shift(const Offset(0, 3)), const Radius.circular(8)),
      Paint()..color = Colors.black26,
    );
    // Tấm gỗ với gradient vân gỗ ấm áp
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB37447), Color(0xFF8D532C)],
        ).createShader(signRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(signRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF4A2E1B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Hai đinh tán kim loại (Rivets) ở góc trên
    final rivetPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawCircle(Offset(signLeft + 8, signTop + 7), 2.2, rivetPaint);
    canvas.drawCircle(Offset(signRect.right - 8, signTop + 7), 2.2, rivetPaint);

    // Chữ "Level"
    final lvlTitlePainter = TextPainter(
      text: const TextSpan(
        text: 'Level',
        style: TextStyle(
          color: Color(0xFFFFF8E1),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lvlTitlePainter.paint(
      canvas,
      Offset(signRect.center.dx - lvlTitlePainter.width / 2, signTop + 8),
    );

    // Số màn chơi (e.g. 48)
    final int displayLvl = currentLevel == 0 ? 48 : currentLevel;
    final lvlNumPainter = TextPainter(
      text: TextSpan(
        text: '$displayLvl',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lvlNumPainter.paint(
      canvas,
      Offset(signRect.center.dx - lvlNumPainter.width / 2, signTop + 20),
    );

    // Tính toán vị trí 3 viên nhộng (Streak, Coins, Score)
    final double pillTop = rect.top + 14.0;
    const double pillH = 26.0;

    // 2. Viên nhộng Chuỗi Thắng (Streak Flame Pill)
    final double streakLeft = signRect.right + 8.0;
    const double streakW = 76.0;
    final Rect streakRect = Rect.fromLTWH(streakLeft, pillTop, streakW, pillH);

    _drawPillBackground(canvas, streakRect, borderColor: const Color(0xFFFF9800));

    // Chữ "Streak x3"
    final streakPainter = TextPainter(
      text: TextSpan(
        text: 'Streak x$streak',
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 10.0,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    streakPainter.paint(
      canvas,
      Offset(streakRect.center.dx - streakPainter.width / 2, streakRect.center.dy - streakPainter.height / 2),
    );

    // Ngọn lửa hoạt họa bùng cháy trên viền trên viên nhộng (Animated Flame)
    _drawFlameIcon(canvas, Offset(streakRect.center.dx, streakRect.top - 1));

    // 3. Viên nhộng Tiền Vàng (Gold Coin Pill: 👑 2,450)
    final double coinLeft = streakRect.right + 6.0;
    const double coinW = 78.0;
    final Rect coinRect = Rect.fromLTWH(coinLeft, pillTop, coinW, pillH);

    _drawPillBackground(canvas, coinRect, borderColor: const Color(0xFFFFD84D));

    // Icon đồng xu vàng / vương miện bên trái
    final crownPainter = TextPainter(
      text: const TextSpan(text: '👑', style: TextStyle(fontSize: 12.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    crownPainter.paint(canvas, Offset(coinRect.left + 6.0, coinRect.center.dy - crownPainter.height / 2));

    // Số tiền (e.g. 2,450)
    final coinNumPainter = TextPainter(
      text: TextSpan(
        text: _formatNumber(coins),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coinNumPainter.paint(canvas, Offset(coinRect.left + 23.0, coinRect.center.dy - coinNumPainter.height / 2));

    // 4. Viên nhộng Cúp Điểm Số (Trophy Pill: 12,500 🏆)
    final double trophyLeft = rect.right - 88.0;
    const double trophyW = 82.0;
    final Rect trophyRect = Rect.fromLTWH(trophyLeft, pillTop, trophyW, pillH);

    _drawPillBackground(canvas, trophyRect, borderColor: const Color(0xFFFFD84D));

    // Điểm số bên trái
    final scorePainter = TextPainter(
      text: TextSpan(
        text: _formatNumber(score),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scorePainter.paint(canvas, Offset(trophyRect.left + 8.0, trophyRect.center.dy - scorePainter.height / 2));

    // Icon Cúp vàng 🏆 bên phải
    final trophyIconPainter = TextPainter(
      text: const TextSpan(text: '🏆', style: TextStyle(fontSize: 13.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    trophyIconPainter.paint(canvas, Offset(trophyRect.right - 18.0, trophyRect.center.dy - trophyIconPainter.height / 2));
  }

  void _drawPillBackground(Canvas canvas, Rect rect, {required Color borderColor}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 1.5)), const Radius.circular(13)),
      Paint()..color = Colors.black26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(13)),
      Paint()..color = const Color(0xFF2B1D14).withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(13)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// Vẽ biểu tượng ngọn lửa bùng cháy rực rỡ với nhịp lung linh
  void _drawFlameIcon(Canvas canvas, Offset center) {
    final double flicker = 1.0 + 0.12 * math.sin(elapsedSec * 8.0);
    final double w = 14.0 * flicker;
    final double h = 18.0 * flicker;

    // Ngọn lửa cam bên ngoài
    final outerFlame = Path()
      ..moveTo(center.dx, center.dy - h)
      ..quadraticBezierTo(center.dx + w * 0.6, center.dy - h * 0.5, center.dx + w * 0.45, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 2, center.dx - w * 0.45, center.dy)
      ..quadraticBezierTo(center.dx - w * 0.6, center.dy - h * 0.5, center.dx, center.dy - h)
      ..close();
    canvas.drawPath(outerFlame, Paint()..color = const Color(0xFFFF5722));

    // Lõi lửa vàng rực bên trong
    final innerFlame = Path()
      ..moveTo(center.dx, center.dy - h * 0.65)
      ..quadraticBezierTo(center.dx + w * 0.35, center.dy - h * 0.3, center.dx + w * 0.25, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 1, center.dx - w * 0.25, center.dy)
      ..quadraticBezierTo(center.dx - w * 0.35, center.dy - h * 0.3, center.dx, center.dy - h * 0.65)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFEB3B));
  }

  /// 6. Ghế Chờ Holding Dock: Gồm 2 Chiếc Ghế Riêng Biệt chuẩn ảnh mẫu:
  /// - Ghế Trái (Standard Holding Dock 3 chỗ) có nhãn "Holding Dock" bên dưới
  /// - Ghế Phải (VIP Bench 2 chỗ) có khắc chữ "VIP" trên tựa lưng
  void _drawHoldingDockBench(Canvas canvas) {
    if (scaler.dockSlotRects.isEmpty) return;

    final int totalSlots = scaler.dockSlotRects.length;
    final int leftCount = totalSlots <= 5 ? 3 : (totalSlots - 2);

    // Ghế Trái (Standard Holding Dock: slots 0 .. leftCount - 1)
    _drawSingleParkBench(
      canvas: canvas,
      startSlot: 0,
      endSlot: leftCount,
      isVip: false,
      subtitleLabel: 'Holding Dock',
    );

    // Ghế Phải (VIP Bench: slots leftCount .. totalSlots)
    _drawSingleParkBench(
      canvas: canvas,
      startSlot: leftCount,
      endSlot: totalSlots,
      isVip: true,
      backrestLabel: 'VIP',
    );
  }

  void _drawSingleParkBench({
    required Canvas canvas,
    required int startSlot,
    required int endSlot,
    required bool isVip,
    String? subtitleLabel,
    String? backrestLabel,
  }) {
    if (startSlot >= scaler.dockSlotRects.length || endSlot > scaler.dockSlotRects.length) return;

    final double benchLeft = scaler.dockSlotRects[startSlot].left - 8;
    final double benchRight = scaler.dockSlotRects[endSlot - 1].right + 8;
    final double benchWidth = benchRight - benchLeft;
    final Rect seatBandRect = Rect.fromLTWH(
      benchLeft,
      scaler.dockSlotRects[startSlot].top - 3,
      benchWidth,
      scaler.dockSlotRects[startSlot].height + 6,
    );

    // 1. Bóng đổ mềm của ghế xuống mặt cỏ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(benchLeft + 3, seatBandRect.bottom + 3, benchWidth - 6, 7),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // 2. Chân ghế kim loại tối màu
    final Paint legPaint = Paint()..color = const Color(0xFF3E2723);
    for (final legX in [benchLeft + 10, benchRight - 18]) {
      final Rect legRect = Rect.fromLTWH(legX, seatBandRect.bottom - 2, 7, 9);
      canvas.drawRRect(RRect.fromRectAndRadius(legRect, const Radius.circular(2)), legPaint);
    }

    // 3. Trụ và Tựa Lưng (Backrest)
    final Color woodDark = isVip ? const Color(0xFF8D532C) : const Color(0xFF5D3A1F);
    final Color woodLight1 = isVip ? const Color(0xFFD49C52) : const Color(0xFFB37447);
    final Color woodLight2 = isVip ? const Color(0xFFB87D0E) : const Color(0xFF9E633A);

    for (final postX in [benchLeft + 10, benchRight - 18]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(postX, seatBandRect.top - 12, 7, 16), const Radius.circular(2)),
        Paint()..color = woodDark,
      );
    }

    final Rect backrestPlank = Rect.fromLTWH(benchLeft + 3, seatBandRect.top - 12, benchWidth - 6, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank.shift(const Offset(0, 1.5)), const Radius.circular(4)),
      Paint()..color = woodDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backrestPlank, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [woodLight1, woodLight2],
        ).createShader(backrestPlank),
    );

    // Chữ VIP khắc trên tựa lưng ghế phải
    if (backrestLabel != null) {
      final vipPainter = TextPainter(
        text: TextSpan(
          text: backrestLabel,
          style: const TextStyle(
            color: Color(0xFFFFF8E1),
            fontSize: 9.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 1)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vipPainter.paint(
        canvas,
        Offset(backrestPlank.center.dx - vipPainter.width / 2, backrestPlank.center.dy - vipPainter.height / 2),
      );
    }

    // 4. Mặt ghế ngồi 2.5D
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect.shift(const Offset(0, 3)), const Radius.circular(9)),
      Paint()..color = woodDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(seatBandRect, const Radius.circular(9)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [woodLight1, woodLight2],
        ).createShader(seatBandRect),
    );

    // 5. Từng ô nệm ngồi và vẽ thú cưng
    for (int i = startSlot; i < endSlot; i++) {
      final slotRect = scaler.dockSlotRects[i];
      final slot = (i < holdingDock.length) ? holdingDock[i] : null;

      final Color cushionColor = isVip ? const Color(0xFFFFE082) : const Color(0xFF4A2E1B);
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
          ..strokeWidth = 1.3,
      );

      // Vạch chia ghế
      if (i < endSlot - 1) {
        final double divX = (slotRect.right + scaler.dockSlotRects[i + 1].left) / 2;
        canvas.drawLine(
          Offset(divX, seatBandRect.top + 3),
          Offset(divX, seatBandRect.bottom - 3),
          Paint()
            ..color = woodDark
            ..strokeWidth = 1.6,
        );
      }

      if (slot != null && slot.isLocked) {
        final lockPaint = Paint()
          ..color = Colors.white60
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(slotRect.center, 5, lockPaint);
      } else if (slot != null && slot.petColor != null) {
        final double side = math.min(slotRect.width, slotRect.height) - 5.0;
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

      // Hiệu ứng hạt sao lấp lánh xoay quanh thú cưng đang bay
      final sparkOffset1 = Offset(math.cos(t * 12.0) * 14.0, math.sin(t * 12.0) * 14.0);
      final sparkOffset2 = Offset(math.cos(t * 12.0 + math.pi) * 11.0, math.sin(t * 12.0 + math.pi) * 11.0);
      canvas.drawCircle(
        pos + sparkOffset1,
        2.2,
        Paint()..color = const Color(0xFFFFD84D).withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        pos + sparkOffset2,
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      // Vệt sáng motion trail phía sau
      canvas.drawCircle(
        pos,
        18,
        Paint()
          ..color = pet.color.lightColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // Độ nghiêng nhào lộn tinh nghịch và phóng to nhẹ khi ở đỉnh vòm nhảy
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
