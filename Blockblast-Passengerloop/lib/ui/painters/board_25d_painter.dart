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

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 9)), const Radius.circular(18)),
      shadowPaint,
    );

    // Viền ngoài 3D #6D4226
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.shift(const Offset(0, 6)), const Radius.circular(18)),
      Paint()..color = const Color(0xFF6D4226),
    );

    // Mặt thành gỗ #9E633A
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(18)),
      Paint()..color = const Color(0xFF9E633A),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.deflate(1.0), const Radius.circular(17)),
      Paint()
        ..color = const Color(0xFFC48354).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Lòng bàn cờ lõm #4A2E1B
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaler.innerGridRect.inflate(2.0), const Radius.circular(12)),
      Paint()..color = const Color(0xFF4A2E1B),
    );

    // Từng ô trống trên lưới 8x8 vẽ RRect bo góc 6px màu #3B2314 có viền sáng nhẹ
    final cellBgPaint = Paint()..color = const Color(0xFF3B2314);
    final cellRimPaint = Paint()
      ..color = const Color(0xFF6B442A).withValues(alpha: 0.65)
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
        final slotRRect = RRect.fromRectAndRadius(cellRect, const Radius.circular(6));
        canvas.drawRRect(slotRRect, cellBgPaint);
        canvas.drawRRect(slotRRect, cellRimPaint);
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
    }

    for (final c in linePreview.fullCols) {
      final colRect = Rect.fromLTWH(
        scaler.innerGridRect.left + c * scaler.cellSize,
        scaler.innerGridRect.top,
        scaler.cellSize,
        scaler.innerGridRect.height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(colRect, const Radius.circular(8)), rimPaint);
    }
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 6)), const Radius.circular(8)),
      Paint()..color = const Color(0xFF424242),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.0), const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
        ).createShader(rect),
    );
    final crackPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + const Offset(-8, -8), center + const Offset(3, 2), crackPaint);
    canvas.drawLine(center + const Offset(3, 2), center + const Offset(8, 9), crackPaint);
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0x99B3E5FC),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    if (iceLayer == 1) {
      final crackPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8;
      canvas.drawLine(center + const Offset(-10, -6), center + const Offset(2, 2), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(11, 8), crackPaint);
      canvas.drawLine(center + const Offset(2, 2), center + const Offset(-4, 12), crackPaint);
    }
  }

  void _drawBombOverlay(Canvas canvas, int r, int c, int turnsLeft) {
    final center = scaler.getCellCenter(r, c);
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFF212121));

    final fusePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.0;
    canvas.drawLine(center + const Offset(4, -10), center + const Offset(8, -14), fusePaint);
    canvas.drawCircle(center + const Offset(8, -14), 2.5, Paint()..color = const Color(0xFFFF1744));

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$turnsLeft',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawVineOverlay(Canvas canvas, int r, int c) {
    final center = scaler.getCellCenter(r, c);
    final vinePaint = Paint()
      ..color = const Color(0xFF2D8512)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(center.dx - 12, center.dy + 12)
      ..quadraticBezierTo(center.dx - 6, center.dy - 6, center.dx + 12, center.dy - 12);
    canvas.drawPath(path, vinePaint);

    final leafPaint = Paint()..color = const Color(0xFF81E659);
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

  /// 10. Chữ nổi (+150, COMBO x3!) nảy lên khi phá hàng
  void _drawComboPopups(Canvas canvas) {
    for (final effect in comboEffects) {
      final yOffset = -32.0 * effect.progress;
      final opacity = (1.0 - effect.progress).clamp(0.0, 1.0);
      final scale = 1.0 + 0.35 * math.sin(effect.progress * math.pi);

      final textPainter = TextPainter(
        text: TextSpan(
          text: effect.text,
          style: TextStyle(
            color: effect.color.withValues(alpha: opacity),
            fontSize: effect.fontSize * scale,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: opacity * 0.85),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        effect.position + Offset(-textPainter.width / 2, yOffset - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant Board25DPainter oldDelegate) => true;
}
