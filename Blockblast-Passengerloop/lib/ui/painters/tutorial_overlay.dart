import 'package:flutter/material.dart';
import '../../core/viewport_scaler.dart';

class TutorialOverlayPainter extends CustomPainter {
  final ViewportScaler scaler;
  final int stepIndex; // 1, 2, or 3
  final String title;
  final String dialogue;
  final int? highlightRow;
  final int targetRow;
  final int targetCol;
  final int startTraySlot;
  final double handProgress; // 0.0 -> 1.0

  TutorialOverlayPainter({
    required this.scaler,
    required this.stepIndex,
    required this.title,
    required this.dialogue,
    this.highlightRow,
    required this.targetRow,
    required this.targetCol,
    required this.startTraySlot,
    required this.handProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawDimmedBackdropWithHoles(canvas, size);
    _drawGlovedHand(canvas);
    _drawCorgiSpeechBubble(canvas);
  }

  /// 1. Làm mờ toàn màn hình và chiếu sáng vùng tiêu điểm
  void _drawDimmedBackdropWithHoles(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(fullRect, Paint());

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.58);
    canvas.drawRect(fullRect, bgPaint);

    // Chiếu sáng hàng mục tiêu trên bàn cờ
    if (highlightRow != null && highlightRow! >= 0 && highlightRow! < 8) {
      final r = highlightRow!;
      final rowRect = Rect.fromLTWH(
        scaler.innerGridRect.left,
        scaler.innerGridRect.top + r * scaler.cellSize,
        scaler.innerGridRect.width,
        scaler.cellSize,
      );

      // Đục lỗ trong suốt trên lớp mờ để làm nổi bật hàng mục tiêu
      canvas.drawRRect(
        RRect.fromRectAndRadius(rowRect, const Radius.circular(6)),
        Paint()..blendMode = BlendMode.clear,
      );

      // Viền vàng nhấp nháy quanh hàng đang chiếu sáng
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD84D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(6)), glowPaint);
    }

    // Chiếu sáng khay gạch bắt đầu
    if (startTraySlot >= 0 && startTraySlot < scaler.traySlotRects.length) {
      final slotRect = scaler.traySlotRects[startTraySlot];
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(10)),
        Paint()..blendMode = BlendMode.clear,
      );

      final slotGlow = Paint()
        ..color = const Color(0xFF4FC3F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(slotRect, const Radius.circular(10)), slotGlow);
    }

    canvas.restore();
  }

  /// 2. Bàn tay trắng chỉ đường (Gloved Hand Pointer) trượt từ khay lên bàn cờ
  void _drawGlovedHand(Canvas canvas) {
    final startPos = (startTraySlot >= 0 && startTraySlot < scaler.traySlotRects.length)
        ? scaler.traySlotRects[startTraySlot].center
        : scaler.zoneDRect.center;

    final targetPos = scaler.getCellCenter(targetRow, targetCol);

    // Trượt mượt mà theo chu kỳ
    final currentPos = Offset(
      startPos.dx + (targetPos.dx - startPos.dx) * handProgress,
      startPos.dy + (targetPos.dy - startPos.dy) * handProgress,
    );

    canvas.save();
    canvas.translate(currentPos.dx, currentPos.dy);

    // Vẽ bàn tay hoạt hình đeo găng trắng
    final glovePaint = Paint()..color = Colors.white;
    final gloveBorder = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Ngón trỏ chỉ lên
    final handPath = Path();
    handPath.moveTo(0, -22);
    handPath.lineTo(8, -12);
    handPath.lineTo(12, 10);
    handPath.lineTo(-12, 10);
    handPath.lineTo(-6, -12);
    handPath.close();

    // Đổ bóng bàn tay
    canvas.drawPath(handPath.shift(const Offset(2, 3)), Paint()..color = Colors.black38);
    canvas.drawPath(handPath, glovePaint);
    canvas.drawPath(handPath, gloveBorder);

    // Cổ găng tay
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, 8, 20, 6), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFD54F),
    );

    canvas.restore();
  }

  /// 3. Corgi Mascot đứng cạnh ghế chờ và hiện bóng thoại hướng dẫn
  void _drawCorgiSpeechBubble(Canvas canvas) {
    final bubbleRect = Rect.fromLTWH(
      16,
      scaler.zoneBRect.top - 70,
      scaler.availableWidth - 32,
      64,
    );

    // Đổ bóng bóng thoại
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect.shift(const Offset(0, 3)), const Radius.circular(14)),
      Paint()..color = Colors.black45,
    );

    // Nền bóng thoại trắng sữa
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFFFFFDE7),
    );

    // Viền cam ấm
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(14)),
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Avatar Corgi Mascot bên trái
    final avatarCenter = Offset(bubbleRect.left + 26, bubbleRect.center.dy);
    canvas.drawCircle(avatarCenter, 18, Paint()..color = const Color(0xFFFF4D4D));
    final avatarPainter = TextPainter(
      text: const TextSpan(text: '🐶', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    );
    avatarPainter.layout();
    avatarPainter.paint(
      canvas,
      avatarCenter - Offset(avatarPainter.width / 2, avatarPainter.height / 2),
    );

    // Tiêu đề & Lời thoại hướng dẫn
    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '$title\n',
          style: const TextStyle(
            color: Color(0xFFD84315),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: dialogue,
          style: const TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 10.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );
    textPainter.layout(maxWidth: bubbleRect.width - 64);
    textPainter.paint(canvas, Offset(bubbleRect.left + 52, bubbleRect.top + 8));
  }

  @override
  bool shouldRepaint(covariant TutorialOverlayPainter oldDelegate) => true;
}
