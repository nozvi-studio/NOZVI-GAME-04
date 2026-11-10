import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/grid_cell_data.dart';
import '../../models/polyomino_shape.dart';
import '../../core/viewport_scaler.dart';

class ComboEffectData {
  final String text;
  final Offset position;
  final double progress; // 0.0 -> 1.0

  const ComboEffectData({
    required this.text,
    required this.position,
    required this.progress,
  });
}

class Board25DPainter extends CustomPainter {
  final ViewportScaler scaler;
  final List<List<GridCellData>> cells;
  final PolyominoShape? draggingShape;
  final PointInt? ghostCell;
  final bool isValidGhost;
  final bool isHammerActive;
  final PointInt? hammerHoverCell;
  final List<ComboEffectData> comboEffects;

  Board25DPainter({
    required this.scaler,
    required this.cells,
    this.draggingShape,
    this.ghostCell,
    this.isValidGhost = false,
    this.isHammerActive = false,
    this.hammerHoverCell,
    this.comboEffects = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWoodenTray(canvas);
    _drawGridCells(canvas);
    _drawGhostPreview(canvas);
    _drawHammerTargetReticle(canvas);
    _drawComboPopups(canvas);
  }

  /// 1. Vẽ khay gỗ 2.5D có thành dày và lòng chảo lõm
  void _drawWoodenTray(Canvas canvas) {
    final boardRect = scaler.boardRect;

    // Đổ bóng mềm bên dưới khay gỗ
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 8)), const Radius.circular(16)),
      shadowPaint,
    );

    // Thành gỗ bên ngoài (màu nâu gỗ ấm 2.5D)
    final outerWoodPaint = Paint()..color = const Color(0xFF8D5B28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(16)),
      outerWoodPaint,
    );

    // Thành dưới dày 6px màu gỗ sẫm tạo độ dày 2.5D
    final bottomRimPaint = Paint()..color = const Color(0xFF5D3A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boardRect.left, boardRect.bottom - 8, boardRect.width, 8),
        const Radius.circular(8),
      ),
      bottomRimPaint,
    );

    // Mặt lòng chảo bên trong (nền bàn cờ lõm)
    final innerPaint = Paint()..color = const Color(0xFF3E2713);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaler.innerGridRect, const Radius.circular(10)),
      innerPaint,
    );

    // Vẽ lưới ô lõm 8x8
    final cellBgPaint = Paint()..color = const Color(0xFF2E1C0C);
    final borderPaint = Paint()
      ..color = const Color(0xFF4A331E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final cellRect = Rect.fromLTWH(
          scaler.innerGridRect.left + c * scaler.cellSize + 1.5,
          scaler.innerGridRect.top + r * scaler.cellSize + 1.5,
          scaler.cellSize - 3.0,
          scaler.cellSize - 3.0,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(cellRect, const Radius.circular(6)), cellBgPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(cellRect, const Radius.circular(6)), borderPaint);
      }
    }
  }

  /// 2. Vẽ các khối gạch 2.5D với độ dày 6px và khuôn mặt thú cưng
  void _drawGridCells(Canvas canvas) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final cell = cells[r][c];
        if (cell.isLocked) {
          _drawLockedCell(canvas, r, c);
        } else if (cell.hazard == HazardType.stone) {
          _drawStoneCell(canvas, r, c);
        } else if (cell.petColor != null) {
          _drawPetTile(canvas, r, c, cell.petColor!, animScale: cell.animScale);
        }

        // Vẽ lớp phủ Hazard nếu có
        if (cell.hazard == HazardType.ice) {
          _drawIceOverlay(canvas, r, c, cell.iceLayer);
        } else if (cell.hazard == HazardType.bomb) {
          _drawBombOverlay(canvas, r, c, cell.bombTurns);
        } else if (cell.hazard == HazardType.vine) {
          _drawVineOverlay(canvas, r, c);
        }
      }
    }
  }

  /// Vẽ khối gạch thú cưng 2.5D: Mặt trên bo góc + Đế dày 6px tối màu
  void _drawPetTile(Canvas canvas, int r, int c, PetColor color, {double animScale = 1.0}) {
    final cellCenter = scaler.getCellCenter(r, c);
    final size = (scaler.cellSize - 4.0) * animScale;
    final half = size / 2;

    canvas.save();
    canvas.translate(cellCenter.dx, cellCenter.dy);

    final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // 1. Đế dày 6px màu sẫm (3D Thickness)
    final baseRect = rect.shift(const Offset(0, 5));
    final baseRRect = RRect.fromRectAndRadius(baseRect, const Radius.circular(8));
    final basePaint = Paint()..color = color.darkColor;
    canvas.drawRRect(baseRRect, basePaint);

    // 2. Mặt trên bo góc tròn
    final topPaint = Paint()..color = color.primaryColor;
    canvas.drawRRect(rrect, topPaint);

    // 3. Viền sáng nhẹ trên mép trên cùng
    final highlightPaint = Paint()
      ..color = color.lightColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, highlightPaint);

    // 4. Vẽ khuôn mặt thú cưng chi tiết
    _drawPetFace(canvas, color, half);

    canvas.restore();
  }

  /// Vẽ khuôn mặt thú cưng vector chi tiết
  void _drawPetFace(Canvas canvas, PetColor color, double half) {
    final eyePaint = Paint()..color = const Color(0xFF212121);
    final eyeGlintPaint = Paint()..color = Colors.white;

    switch (color) {
      case PetColor.red:
        // Corgi Đỏ: Vệt trắng giữa mũi, tai hồng, mũi đen, mắt to tròn
        final snoutPaint = Paint()..color = Colors.white;
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(0, 3), width: half * 0.9, height: half * 0.65),
          snoutPaint,
        );
        // Mắt
        canvas.drawCircle(Offset(-half * 0.45, -half * 0.2), 2.5, eyePaint);
        canvas.drawCircle(Offset(-half * 0.45 - 0.7, -half * 0.2 - 0.7), 1.0, eyeGlintPaint);
        canvas.drawCircle(Offset(half * 0.45, -half * 0.2), 2.5, eyePaint);
        canvas.drawCircle(Offset(half * 0.45 - 0.7, -half * 0.2 - 0.7), 1.0, eyeGlintPaint);
        // Mũi đen
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: 4.5, height: 3.5), eyePaint);
        // Tai Corgi nhô nhẹ
        final earPaint = Paint()..color = const Color(0xFFFF8A80);
        canvas.drawCircle(Offset(-half * 0.7, -half * 0.7), 3.0, earPaint);
        canvas.drawCircle(Offset(half * 0.7, -half * 0.7), 3.0, earPaint);
        break;

      case PetColor.yellow:
        // Mèo Vàng: Tai nhọn tam giác, râu mèo, mắt mèo tinh nghịch
        // Tai
        final earPath = Path();
        earPath.moveTo(-half * 0.8, -half * 0.4);
        earPath.lineTo(-half * 0.5, -half * 0.9);
        earPath.lineTo(-half * 0.2, -half * 0.5);
        earPath.close();
        canvas.drawPath(earPath, Paint()..color = const Color(0xFFE65100));

        final earPathR = Path();
        earPathR.moveTo(half * 0.8, -half * 0.4);
        earPathR.lineTo(half * 0.5, -half * 0.9);
        earPathR.lineTo(half * 0.2, -half * 0.5);
        earPathR.close();
        canvas.drawPath(earPathR, Paint()..color = const Color(0xFFE65100));

        // Mắt
        canvas.drawCircle(Offset(-half * 0.4, -half * 0.1), 2.4, eyePaint);
        canvas.drawCircle(Offset(half * 0.4, -half * 0.1), 2.4, eyePaint);
        // Mũi hồng
        canvas.drawCircle(const Offset(0, 3), 2.0, Paint()..color = const Color(0xFFFF80AB));
        // Râu mèo
        final whiskerPaint = Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(-half * 0.3, 3), Offset(-half * 0.85, 2), whiskerPaint);
        canvas.drawLine(Offset(-half * 0.3, 5), Offset(-half * 0.85, 7), whiskerPaint);
        canvas.drawLine(Offset(half * 0.3, 3), Offset(half * 0.85, 2), whiskerPaint);
        canvas.drawLine(Offset(half * 0.3, 5), Offset(half * 0.85, 7), whiskerPaint);
        break;

      case PetColor.blue:
        // Vịt Xanh Dương: Mỏ vịt cam tròn to bè, mắt tròn long lanh
        canvas.drawCircle(Offset(-half * 0.35, -half * 0.2), 2.6, eyePaint);
        canvas.drawCircle(Offset(-half * 0.35 - 0.8, -half * 0.2 - 0.8), 1.0, eyeGlintPaint);
        canvas.drawCircle(Offset(half * 0.35, -half * 0.2), 2.6, eyePaint);
        canvas.drawCircle(Offset(half * 0.35 - 0.8, -half * 0.2 - 0.8), 1.0, eyeGlintPaint);
        // Mỏ cam tròn
        final beakPaint = Paint()..color = const Color(0xFFFF9800);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, 4), width: half * 0.9, height: half * 0.45),
            const Radius.circular(6),
          ),
          beakPaint,
        );
        break;

      case PetColor.green:
        // Thỏ Xanh Lá: Hai tai dài dựng đứng, má hồng, răng thỏ
        final earPaint = Paint()..color = const Color(0xFFA5D6A7);
        final innerEar = Paint()..color = const Color(0xFFFFCDD2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-half * 0.7, -half * 0.95, 5, 10), const Radius.circular(3)),
          earPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-half * 0.7 + 1, -half * 0.95 + 1, 3, 8), const Radius.circular(2)),
          innerEar,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(half * 0.7 - 5, -half * 0.95, 5, 10), const Radius.circular(3)),
          earPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(half * 0.7 - 4, -half * 0.95 + 1, 3, 8), const Radius.circular(2)),
          innerEar,
        );
        // Mắt & Má hồng
        canvas.drawCircle(Offset(-half * 0.38, -half * 0.1), 2.2, eyePaint);
        canvas.drawCircle(Offset(half * 0.38, -half * 0.1), 2.2, eyePaint);
        final cheekPaint = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.5);
        canvas.drawCircle(Offset(-half * 0.6, 3), 3.0, cheekPaint);
        canvas.drawCircle(Offset(half * 0.6, 3), 3.0, cheekPaint);
        // Mũi & răng
        canvas.drawCircle(const Offset(0, 1), 1.8, Paint()..color = const Color(0xFFE91E63));
        canvas.drawRect(const Rect.fromLTWH(-1.5, 3.5, 3, 3), Paint()..color = Colors.white);
        break;

      case PetColor.orange:
        // Cáo Cam: Má trắng nhọn, đầu tai đen, mắt xếch thông minh
        final cheekPaint = Paint()..color = Colors.white;
        final cheekPath = Path();
        cheekPath.moveTo(-half * 0.8, 3);
        cheekPath.lineTo(0, 7);
        cheekPath.lineTo(half * 0.8, 3);
        cheekPath.lineTo(0, -2);
        cheekPath.close();
        canvas.drawPath(cheekPath, cheekPaint);

        // Tai đầu đen
        canvas.drawCircle(Offset(-half * 0.7, -half * 0.7), 3.5, Paint()..color = Colors.black87);
        canvas.drawCircle(Offset(half * 0.7, -half * 0.7), 3.5, Paint()..color = Colors.black87);

        // Mắt cáo
        canvas.drawOval(Rect.fromCenter(center: Offset(-half * 0.35, -half * 0.1), width: 3, height: 4), eyePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(half * 0.35, -half * 0.1), width: 3, height: 4), eyePaint);
        // Mũi đen nhọn
        canvas.drawCircle(const Offset(0, 6), 2.0, eyePaint);
        break;
    }
  }

  /// 3. Vẽ ô Đá Tảng
  void _drawStoneCell(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 4.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    // Đế đá
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 4)), const Radius.circular(8)),
      Paint()..color = const Color(0xFF424242),
    );
    // Thân đá
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF757575),
    );
    // Vết nứt đá
    final crackPaint = Paint()
      ..color = const Color(0xFF303030)
      ..strokeWidth = 1.5;
    canvas.drawLine(center + const Offset(-8, -8), center + const Offset(4, 2), crackPaint);
    canvas.drawLine(center + const Offset(4, 2), center + const Offset(8, 10), crackPaint);
  }

  /// 4. Vẽ ô bị khóa (Hố đen hoặc góc dị hình)
  void _drawLockedCell(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 4.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = Colors.black87,
    );
    // Biểu tượng ổ khóa
    final lockPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center + const Offset(0, -3), 4, lockPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: center + const Offset(0, 4), width: 12, height: 10), const Radius.circular(2)),
      Paint()..color = Colors.white70,
    );
  }

  /// 5. Lớp phủ Băng Giá (ICE 2 lớp)
  void _drawIceOverlay(Canvas canvas, int r, int c, int iceLayer) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 3.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    // Lớp băng xanh trong suốt
    final icePaint = Paint()
      ..color = const Color(0x99B3E5FC)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), icePaint);

    // Viền băng
    final borderPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    if (iceLayer == 1) {
      // Băng nứt: vẽ vết rạn nứt trắng
      final crackPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8;
      canvas.drawLine(center + const Offset(-10, -6), center + const Offset(2, 2), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(11, 8), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(-4, 12), crackPaint);
    }
  }

  /// 6. Lớp phủ Bom Hẹn Giờ
  void _drawBombOverlay(Canvas canvas, int r, int c, int turnsLeft) {
    final center = scaler.getCellCenter(r, c);

    // Quả bom tròn đen
    final bombPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(center, 12, bombPaint);

    // Ngòi nổ & tia lửa
    final fusePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.0;
    canvas.drawLine(center + const Offset(4, -10), center + const Offset(8, -14), fusePaint);
    canvas.drawCircle(center + const Offset(8, -14), 2.5, Paint()..color = const Color(0xFFFF1744));

    // Huy hiệu đếm ngược
    final textSpan = TextSpan(
      text: '$turnsLeft',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  /// 7. Lớp phủ Dây Leo xanh
  void _drawVineOverlay(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final vinePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(center.dx - 12, center.dy + 12);
    path.quadraticBezierTo(center.dx - 6, center.dy - 6, center.dx + 12, center.dy - 12);
    canvas.drawPath(path, vinePaint);

    // Lá cây nhỏ
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(Rect.fromCenter(center: center + const Offset(-4, 0), width: 6, height: 4), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: center + const Offset(6, -2), width: 6, height: 4), leafPaint);
  }

  /// 8. Bóng mờ Ghost Preview khi kéo khối gạch vào bàn cờ
  void _drawGhostPreview(Canvas canvas) {
    if (draggingShape == null || ghostCell == null) return;

    for (final tile in draggingShape!.tiles) {
      final targetR = ghostCell!.r + tile.r;
      final targetC = ghostCell!.c + tile.c;

      if (targetR < 0 || targetR >= 8 || targetC < 0 || targetC >= 8) continue;

      final center = scaler.getCellCenter(targetR, targetC);
      final size = scaler.cellSize - 4.0;
      final rect = Rect.fromCenter(center: center, width: size, height: size);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      final ghostPaint = Paint()
        ..color = isValidGhost
            ? tile.petColor.primaryColor.withValues(alpha: 0.55)
            : const Color(0x66FF1744)
        ..style = PaintingStyle.fill;

      final ghostBorder = Paint()
        ..color = isValidGhost ? Colors.white70 : const Color(0xFFFF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(rrect, ghostPaint);
      canvas.drawRRect(rrect, ghostBorder);
    }
  }

  /// 9. Vòng tròn ngắm Búa Rèn Lửa 3x3
  void _drawHammerTargetReticle(Canvas canvas) {
    if (!isHammerActive || hammerHoverCell == null) return;

    final minR = math.max(0, hammerHoverCell!.r - 1);
    final maxR = math.min(7, hammerHoverCell!.r + 1);
    final minC = math.max(0, hammerHoverCell!.c - 1);
    final maxC = math.min(7, hammerHoverCell!.c + 1);

    final topLeft = scaler.getCellCenter(minR, minC) - Offset(scaler.cellSize / 2, scaler.cellSize / 2);
    final bottomRight = scaler.getCellCenter(maxR, maxC) + Offset(scaler.cellSize / 2, scaler.cellSize / 2);
    final areaRect = Rect.fromPoints(topLeft, bottomRight);

    final areaPaint = Paint()..color = const Color(0x44FF3D00);
    final borderPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(RRect.fromRectAndRadius(areaRect, const Radius.circular(12)), areaPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(areaRect, const Radius.circular(12)), borderPaint);
  }

  /// 10. Chữ nổi Combo x2!, Combo x4! nảy lên khi phá hàng
  void _drawComboPopups(Canvas canvas) {
    for (final effect in comboEffects) {
      final yOffset = -25.0 * effect.progress;
      final opacity = (1.0 - effect.progress).clamp(0.0, 1.0);
      final scale = 1.0 + 0.3 * math.sin(effect.progress * math.pi);

      final textSpan = TextSpan(
        text: effect.text,
        style: TextStyle(
          color: const Color(0xFFFFD600).withValues(alpha: opacity),
          fontSize: 26 * scale,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: opacity * 0.8),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(
        canvas,
        effect.position + Offset(-textPainter.width / 2, yOffset - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant Board25DPainter oldDelegate) => true;
}

