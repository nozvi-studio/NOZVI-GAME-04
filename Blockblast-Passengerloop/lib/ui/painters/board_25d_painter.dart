import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/grid_cell_data.dart';
import '../../models/polyomino_shape.dart';
import '../../core/viewport_scaler.dart';
import '../../logic/grid_engine.dart';
import 'kawaii_25d_renderer.dart';

class ComboEffectData {
  final String text;
  final Offset position;
  final double progress; // 0.0 -> 1.0
  final Color color;
  final double fontSize;

  const ComboEffectData({
    required this.text,
    required this.position,
    required this.progress,
    this.color = const Color(0xFFFFD84D),
    this.fontSize = 26.0,
  });
}

/// Hàm vẽ khối gạch thú cưng Toy 2.5D chuẩn 6 lớp (ủy quyền cho Kawaii25DRenderer)
void draw25DPetBlock(Canvas canvas, Rect cellRect, PetColor color) {
  Kawaii25DRenderer.drawKawaiiPetBlock(canvas, cellRect, color);
}

/// CustomPainter vẽ một khối gạch Polyomino bằng Kawaii25DRenderer
/// Dùng chung cho Khay Next (tỉ lệ 0.62x) và khối đang kéo trên màn hình (tỉ lệ 1.0x)
class PolyominoShape25DPainter extends CustomPainter {
  final PolyominoShape shape;
  final double cellSize;
  final GameSkinTheme skin;

  const PolyominoShape25DPainter({
    required this.shape,
    required this.cellSize,
    this.skin = GameSkinTheme.kawaiiPets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / (shape.width * cellSize);
    final double scaleY = size.height / (shape.height * cellSize);
    final double scale = math.min(scaleX, scaleY);

    canvas.save();
    canvas.scale(scale, scale);

    for (final tile in shape.tiles) {
      final cellRect = Rect.fromLTWH(
        tile.c * cellSize + 1.5,
        tile.r * cellSize + 1.5,
        cellSize - 3.0,
        cellSize - 3.0,
      );
      Kawaii25DRenderer.drawBlock(
        canvas,
        cellRect,
        tile.petColor,
        skin: skin,
        animateIdle: false,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PolyominoShape25DPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.skin != skin;
  }
}

class Board25DPainter extends CustomPainter {
  final ViewportScaler scaler;
  final List<List<GridCellData>> cells;
  final PolyominoShape? draggingShape;
  final PointInt? ghostCell;
  final bool isValidGhost;
  final LinePreviewResult linePreview;
  final bool isHammerActive;
  final PointInt? hammerHoverCell;
  final List<ComboEffectData> comboEffects;
  final GameSkinTheme skin;
  final double Function()? getElapsedSec;

  // Cached Static Paints to eliminate GC pressure during 60fps rendering
  static final Paint _boardShadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _board3DRimPaint = Paint()..color = const Color(0xFF6D4226);
  static final Paint _boardWoodFacePaint = Paint()..color = const Color(0xFF9E633A);
  static final Paint _boardHighlightPaint = Paint()
    ..color = const Color(0xFFC48354).withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _boardInnerWellPaint = Paint()..color = const Color(0xFF4A2E1B);
  static final Paint _cellBgPaint = Paint()..color = const Color(0xFF3B2314);
  static final Paint _cellRimPaint = Paint()
    ..color = const Color(0xFF6B442A).withValues(alpha: 0.65)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  Board25DPainter({
    required this.scaler,
    required this.cells,
    this.draggingShape,
    this.ghostCell,
    this.isValidGhost = false,
    this.linePreview = const LinePreviewResult(),
    this.isHammerActive = false,
    this.hammerHoverCell,
    this.comboEffects = const [],
    this.skin = GameSkinTheme.kawaiiPets,
    this.getElapsedSec,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double elapsedSec = getElapsedSec != null ? getElapsedSec!() : 0.0;

    _drawWoodenTray(canvas);
    _drawLinePreviewUnderlayGlow(canvas, elapsedSec);
    _drawGhostPreview(canvas);
    _drawGridCells(canvas, elapsedSec);
    _drawLinePreviewOverlayRim(canvas, elapsedSec);
    _drawHammerTargetReticle(canvas);
    _drawComboPopups(canvas);
  }

  /// 1. Vẽ khay gỗ 8x8 Toy 2.5D chuẩn bảng màu Hex (#6D4226, #9E633A, #4A2E1B, #3B2314)
  void _drawWoodenTray(Canvas canvas) {
    final boardRect = scaler.boardRect;

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 9)), const Radius.circular(18)),
      _boardShadowPaint,
    );

    // Viền ngoài 3D #6D4226
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 6)), const Radius.circular(18)),
      _board3DRimPaint,
    );

    // Mặt thành gỗ #9E633A
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(18)),
      _boardWoodFacePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.deflate(1.0), const Radius.circular(17)),
      _boardHighlightPaint,
    );

    // Lòng bàn cờ lõm #4A2E1B
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaler.innerGridRect.inflate(2.0), const Radius.circular(12)),
      _boardInnerWellPaint,
    );

    // Từng ô trống trên lưới 8x8 vẽ RRect bo góc 6px màu #3B2314 có viền sáng nhẹ
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final cellRect = Rect.fromLTWH(
          scaler.innerGridRect.left + c * scaler.cellSize + 1.5,
          scaler.innerGridRect.top + r * scaler.cellSize + 1.5,
          scaler.cellSize - 3.0,
          scaler.cellSize - 3.0,
        );
        final slotRRect = RRect.fromRectAndRadius(cellRect, const Radius.circular(6));
        canvas.drawRRect(slotRRect, _cellBgPaint);
        canvas.drawRRect(slotRRect, _cellRimPaint);
      }
    }
  }

  /// Highlight nền phát sáng rực rỡ các hàng/cột sắp nổ (từ previewLinesIfPlaced)
  void _drawLinePreviewUnderlayGlow(Canvas canvas, double elapsedSec) {
    if (!linePreview.hasLinesToClear) return;

    final double pulse = 0.55 + 0.30 * math.sin(elapsedSec * 9.0);
    final glowPaint = Paint()
      ..color = const Color(0xFFFFEE58).withValues(alpha: 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final r in linePreview.fullRows) {
      final rowRect = Rect.fromLTWH(
        scaler.innerGridRect.left,
        scaler.innerGridRect.top + r * scaler.cellSize,
        scaler.innerGridRect.width,
        scaler.cellSize,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(8)), glowPaint);
    }

    for (final c in linePreview.fullCols) {
      final colRect = Rect.fromLTWH(
        scaler.innerGridRect.left + c * scaler.cellSize,
        scaler.innerGridRect.top,
        scaler.cellSize,
        scaler.innerGridRect.height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(colRect, const Radius.circular(8)), glowPaint);
    }
  }

  void _drawLinePreviewOverlayRim(Canvas canvas, double elapsedSec) {
    if (!linePreview.hasLinesToClear) return;

    final double pulse = 0.65 + 0.35 * math.sin(elapsedSec * 10.0);
    final rimPaint = Paint()
      ..color = const Color(0xFFFFEE58).withValues(alpha: pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (final r in linePreview.fullRows) {
      final rowRect = Rect.fromLTWH(
        scaler.innerGridRect.left,
        scaler.innerGridRect.top + r * scaler.cellSize,
        scaler.innerGridRect.width,
        scaler.cellSize,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rowRect, const Radius.circular(8)), rimPaint);

      // Dấu chân thú cưng 🐾 và tia sao vàng lấp lánh trên hàng sắp nổ chuẩn ảnh mẫu
      for (int c = 0; c < 8; c++) {
        final cellCenter = scaler.getCellCenter(r, c);
        final pawPainter = TextPainter(
          text: TextSpan(
            text: '🐾',
            style: TextStyle(
              fontSize: scaler.cellSize * 0.35,
              color: const Color(0xFFFFE082).withValues(alpha: 0.9 * pulse),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        pawPainter.paint(canvas, cellCenter - Offset(pawPainter.width / 2, pawPainter.height / 2));

        final starPaint = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: pulse);
        _draw4PointStar(canvas, cellCenter + Offset(scaler.cellSize * 0.40, 0), 5.0 * pulse, starPaint);
      }
    }

    for (final c in linePreview.fullCols) {
      final colRect = Rect.fromLTWH(
        scaler.innerGridRect.left + c * scaler.cellSize,
        scaler.innerGridRect.top,
        scaler.cellSize,
        scaler.innerGridRect.height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(colRect, const Radius.circular(8)), rimPaint);

      for (int r = 0; r < 8; r++) {
        final cellCenter = scaler.getCellCenter(r, c);
        final pawPainter = TextPainter(
          text: TextSpan(
            text: '🐾',
            style: TextStyle(
              fontSize: scaler.cellSize * 0.35,
              color: const Color(0xFFFFE082).withValues(alpha: 0.9 * pulse),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        pawPainter.paint(canvas, cellCenter - Offset(pawPainter.width / 2, pawPainter.height / 2));

        final starPaint = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: pulse);
        _draw4PointStar(canvas, cellCenter + Offset(0, scaler.cellSize * 0.40), 5.0 * pulse, starPaint);
      }
    }
  }

  void _draw4PointStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// 2. Vẽ các khối gạch 2.5D bằng Kawaii25DRenderer với nhịp thở & chớp mắt 60fps
  void _drawGridCells(Canvas canvas, double elapsedSec) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final cell = cells[r][c];
        if (cell.isLocked) {
          _drawLockedCell(canvas, r, c);
        } else if (cell.hazard == HazardType.stone) {
          _drawStoneCell(canvas, r, c);
        } else if (cell.petColor != null) {
          _drawPetTile(canvas, r, c, cell.petColor!, animScale: cell.animScale, elapsedSec: elapsedSec);
        }

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

  void _drawPetTile(
    Canvas canvas,
    int r,
    int c,
    PetColor color, {
    double animScale = 1.0,
    double elapsedSec = 0.0,
  }) {
    final cellCenter = scaler.getCellCenter(r, c);
    final size = (scaler.cellSize - 3.0) * animScale;
    final cellRect = Rect.fromCenter(center: cellCenter, width: size, height: size);
    Kawaii25DRenderer.drawBlock(
      canvas,
      cellRect,
      color,
      skin: skin,
      elapsedSec: elapsedSec,
      seed: r * 8 + c,
    );
  }

  void _drawStoneCell(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 3.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    // 1. Đế đổ bóng 3D
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 5)), const Radius.circular(8)),
      Paint()..color = const Color(0xFF37474F),
    );
    // 2. Thân khối đá xám chiseled
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE), Color(0xFF607D8B)],
        ).createShader(rect),
    );
    // Viền vát cạnh
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFECEFF1).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3. Các đường nứt tự nhiên tỏa nhánh chuẩn ảnh mẫu
    final crackPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + const Offset(-10, -9), center + const Offset(-2, -2), crackPaint);
    canvas.drawLine(center + const Offset(-2, -2), center + const Offset(6, -7), crackPaint);
    canvas.drawLine(center + const Offset(-2, -2), center + const Offset(3, 5), crackPaint);
    canvas.drawLine(center + const Offset(3, 5), center + const Offset(9, 9), crackPaint);
    canvas.drawLine(center + const Offset(3, 5), center + const Offset(-7, 8), crackPaint);
  }

  void _drawLockedCell(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 4.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF1F1610),
    );
    final lockPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center + const Offset(0, -3), 4, lockPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(0, 4), width: 12, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white70,
    );
  }

  void _drawIceOverlay(Canvas canvas, int r, int c, int iceLayer) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 2.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Lớp băng pha lê xanh ngọc bóng bẩy
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xCCE1F5FE),
            const Color(0x9981D4FA),
            const Color(0xBB4FC3F7),
          ],
        ).createShader(rect),
    );

    // Dải bóng kính chéo (Gloss Sheen Strips) đặc trưng trong ảnh mẫu
    final Path sheen1 = Path()
      ..moveTo(rect.left + rect.width * 0.20, rect.top + 2)
      ..lineTo(rect.left + rect.width * 0.48, rect.top + 2)
      ..lineTo(rect.left + 2, rect.top + rect.height * 0.48)
      ..lineTo(rect.left + 2, rect.top + rect.height * 0.20)
      ..close();
    canvas.drawPath(sheen1, Paint()..color = Colors.white.withValues(alpha: 0.65));

    final Path sheen2 = Path()
      ..moveTo(rect.left + rect.width * 0.60, rect.top + 2)
      ..lineTo(rect.left + rect.width * 0.88, rect.top + 2)
      ..lineTo(rect.left + 2, rect.top + rect.height * 0.88)
      ..lineTo(rect.left + 2, rect.top + rect.height * 0.60)
      ..close();
    canvas.drawPath(sheen2, Paint()..color = Colors.white.withValues(alpha: 0.48));

    // Viền băng trắng nổi
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    if (iceLayer == 1) {
      final crackPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0;
      canvas.drawLine(center + const Offset(-10, -6), center + const Offset(2, 2), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(11, 8), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(-4, 12), crackPaint);
    }
  }

  void _drawBombOverlay(Canvas canvas, int r, int c, int turnsLeft) {
    final center = scaler.getCellCenter(r, c);
    final double radius = 13.5;

    // Quả bom tròn 3D có bóng và khối gradient
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            const Color(0xFF546E7A),
            const Color(0xFF263238),
            const Color(0xFF102027),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Vành kim loại ngòi nổ
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + Offset(4, -radius), width: 6, height: 3.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF78909C),
    );

    // Dây cháy uốn cong
    final fusePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fusePath = Path()
      ..moveTo(center.dx + 4, center.dy - radius)
      ..quadraticBezierTo(center.dx + 9, center.dy - radius - 5, center.dx + 11, center.dy - radius - 2);
    canvas.drawPath(fusePath, fusePaint);

    // Đốm lửa ngòi nổ bốc cháy rực rỡ
    canvas.drawCircle(center + Offset(11, -radius - 2), 3.2, Paint()..color = const Color(0xFFFF3D00));
    canvas.drawCircle(center + Offset(11, -radius - 2), 1.8, Paint()..color = const Color(0xFFFFEA00));

    // Con số đếm ngược màu trắng to rõ nét ở tâm quả bom
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$turnsLeft',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawVineOverlay(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final size = scaler.cellSize - 4.0;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    final vinePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dây leo gai quấn quanh khung ô vuông
    final vinePath = Path()
      ..moveTo(rect.left + 2, rect.bottom - 4)
      ..lineTo(rect.left + 2, rect.top + 4)
      ..lineTo(rect.right - 4, rect.top + 4)
      ..lineTo(rect.right - 4, rect.bottom - 2)
      ..lineTo(rect.left + 6, rect.bottom - 2);
    canvas.drawPath(vinePath, vinePaint);

    // Lá cây gai xanh nhô ra ở 4 cạnh
    final leafPaint = Paint()..color = const Color(0xFF43A047);
    for (final pt in [
      Offset(rect.left + 2, rect.center.dy - 5),
      Offset(rect.center.dx - 4, rect.top + 4),
      Offset(rect.right - 4, rect.center.dy + 4),
      Offset(rect.center.dx + 4, rect.bottom - 2),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: pt, width: 6.5, height: 4.5), leafPaint);
    }
  }

  /// 8. Bóng mờ Ghost Preview khi kéo khối gạch vào bàn cờ
  void _drawGhostPreview(Canvas canvas) {
    if (draggingShape == null || ghostCell == null) return;

    for (final tile in draggingShape!.tiles) {
      final targetR = ghostCell!.r + tile.r;
      final targetC = ghostCell!.c + tile.c;

      if (targetR < 0 || targetR >= 8 || targetC < 0 || targetC >= 8) continue;

      final center = scaler.getCellCenter(targetR, targetC);
      final size = scaler.cellSize - 3.0;
      final rect = Rect.fromCenter(center: center, width: size, height: size);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      final ghostPaint = Paint()
        ..color = isValidGhost
            ? tile.petColor.topGradientStart.withValues(alpha: 0.45)
            : const Color(0x66FF1744)
        ..style = PaintingStyle.fill;

      final ghostBorder = Paint()
        ..color = isValidGhost ? Colors.white : const Color(0xFFFF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(rrect, ghostPaint);
      canvas.drawRRect(rrect, ghostBorder);
    }
  }

  void _drawHammerTargetReticle(Canvas canvas) {
    if (!isHammerActive || hammerHoverCell == null) return;

    final minR = math.max(0, hammerHoverCell!.r - 1);
    final maxR = math.min(7, hammerHoverCell!.r + 1);
    final minC = math.max(0, hammerHoverCell!.c - 1);
    final maxC = math.min(7, hammerHoverCell!.c + 1);

    final topLeft = scaler.getCellCenter(minR, minC) - Offset(scaler.cellSize / 2, scaler.cellSize / 2);
    final bottomRight = scaler.getCellCenter(maxR, maxC) + Offset(scaler.cellSize / 2, scaler.cellSize / 2);
    final areaRect = Rect.fromPoints(topLeft, bottomRight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(areaRect, const Radius.circular(12)),
      Paint()..color = const Color(0x44FF3D00),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(areaRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFFFF3D00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  /// 10. Chữ nổi (+150, COMBO x4!) phong cách hoạt hình 3D nảy lên khi phá hàng chuẩn ảnh mẫu
  void _drawComboPopups(Canvas canvas) {
    for (final effect in comboEffects) {
      final yOffset = -36.0 * effect.progress;
      final opacity = (1.0 - effect.progress).clamp(0.0, 1.0);
      final scale = 1.0 + 0.38 * math.sin(effect.progress * math.pi);
      final center = effect.position + Offset(0, yOffset);

      final isCombo = effect.text.toUpperCase().contains('COMBO');
      final double fontSize = (isCombo ? 28.0 : effect.fontSize) * scale;

      // 1. Lớp viền nét dày màu nâu đậm (#2B1D14) tạo phong cách Comic
      final strokePainter = TextPainter(
        text: TextSpan(
          text: effect.text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isCombo ? 5.0 : 3.5
              ..color = const Color(0xFF2B1D14).withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Đổ bóng chữ
      strokePainter.paint(
        canvas,
        center + Offset(-strokePainter.width / 2 + 2, -strokePainter.height / 2 + 3),
      );
      strokePainter.paint(
        canvas,
        center - Offset(strokePainter.width / 2, strokePainter.height / 2),
      );

      // 2. Lớp chữ ruột vàng cam rực rỡ
      final fillPainter = TextPainter(
        text: TextSpan(
          text: effect.text,
          style: TextStyle(
            color: (isCombo ? const Color(0xFFFFD84D) : effect.color).withValues(alpha: opacity),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      fillPainter.paint(
        canvas,
        center - Offset(fillPainter.width / 2, fillPainter.height / 2),
      );

      // 3. Các hạt sao lấp lánh (Sparkle Stars) bay quanh chữ Combo
      if (isCombo) {
        final starPaint = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: opacity);
        final double starDist = fillPainter.width * 0.55;
        canvas.drawCircle(center + Offset(-starDist, -8), 3.0 * scale, starPaint);
        canvas.drawCircle(center + Offset(starDist, -4), 2.5 * scale, starPaint);
        canvas.drawCircle(center + Offset(starDist + 8, 8), 1.8 * scale, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Board25DPainter oldDelegate) => true;
}
