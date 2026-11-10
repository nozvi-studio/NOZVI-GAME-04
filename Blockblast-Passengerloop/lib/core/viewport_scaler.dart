import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/polyomino_shape.dart';

/// Quản lý phân vùng giao diện dọc 9:16 và chuyển đổi tọa độ chạm
class ViewportScaler {
  final Size screenSize;
  final EdgeInsets padding;

  late final double availableWidth;
  late final double availableHeight;

  // 4 Phân vùng chiều cao chính theo đặc tả AGENT_SPEC
  late final Rect zoneARect; // Zone A: Trạm xe buýt & HUD (22%)
  late final Rect zoneBRect; // Zone B: Ghế chờ Holding Dock 5 chỗ (10%)
  late final Rect zoneCRect; // Zone C: Bàn cờ gỗ 8x8 2.5D (48%)
  late final Rect zoneDRect; // Zone D: Khay gạch Next & 2 nút Cổ vật (20%)

  // Kích thước & Tọa độ Bàn cờ 8x8
  late final Rect boardRect;
  late final Rect innerGridRect;
  late final double boardThickness;
  late final double cellSize;

  // Tọa độ 5 vị trí ghế ngồi trên Holding Dock
  final List<Rect> dockSlotRects = [];

  // Tọa độ 3 khay chứa gạch ở Zone D
  final List<Rect> traySlotRects = [];

  // Tọa độ 2 nút Cổ vật ở Zone D
  late final Rect hammerButtonRect;
  late final Rect compassButtonRect;

  /// Độ lệch Y khi kéo ngón tay trên màn hình cảm ứng để không che mất khối gạch
  static const double touchOffsetY = -70.0;

  final int dockCapacity;

  ViewportScaler({
    required this.screenSize,
    required this.padding,
    this.dockCapacity = 5,
  }) {
    _calculateLayout();
  }

  void _calculateLayout() {
    availableWidth = screenSize.width;
    availableHeight = screenSize.height - padding.top - padding.bottom;

    final topOffset = padding.top;

    final hA = availableHeight * 0.22;
    final hB = availableHeight * 0.10;
    final hC = availableHeight * 0.48;
    final hD = availableHeight * 0.20;

    zoneARect = Rect.fromLTWH(0, topOffset, availableWidth, hA);
    zoneBRect = Rect.fromLTWH(0, topOffset + hA, availableWidth, hB);
    zoneCRect = Rect.fromLTWH(0, topOffset + hA + hB, availableWidth, hC);
    zoneDRect = Rect.fromLTWH(0, topOffset + hA + hB + hC, availableWidth, hD);

    // 1. Tính toán Bàn cờ 8x8 trong Zone C
    boardThickness = 10.0;
    final maxBoardSide = math.min(availableWidth * 0.94, hC * 0.96);
    final boardCenter = Offset(availableWidth / 2, zoneCRect.top + zoneCRect.height / 2);
    boardRect = Rect.fromCenter(center: boardCenter, width: maxBoardSide, height: maxBoardSide);

    innerGridRect = Rect.fromLTWH(
      boardRect.left + boardThickness,
      boardRect.top + boardThickness,
      boardRect.width - boardThickness * 2,
      boardRect.height - boardThickness * 2,
    );
    cellSize = innerGridRect.width / 8.0;

    // 2. Tính toán các ghế ngồi của Holding Dock trong Zone B
    dockSlotRects.clear();
    final benchWidth = math.min(availableWidth * 0.92, 380.0);
    final benchLeft = (availableWidth - benchWidth) / 2;
    final slotWidth = benchWidth / math.max(1, dockCapacity);
    final slotHeight = math.min(zoneBRect.height * 0.75, 46.0);
    final slotTop = zoneBRect.top + (zoneBRect.height - slotHeight) / 2;

    for (int i = 0; i < dockCapacity; i++) {
      dockSlotRects.add(Rect.fromLTWH(
        benchLeft + i * slotWidth + 3,
        slotTop,
        slotWidth - 6,
        slotHeight,
      ));
    }

    // 3. Tính toán Zone D: 2 nút Cổ vật và 3 khay gạch Next
    final btnDiameter = math.min(54.0, zoneDRect.height * 0.58);
    final btnTop = zoneDRect.top + (zoneDRect.height - btnDiameter) / 2;
    hammerButtonRect = Rect.fromLTWH(14.0, btnTop, btnDiameter, btnDiameter);
    compassButtonRect = Rect.fromLTWH(availableWidth - btnDiameter - 14.0, btnTop, btnDiameter, btnDiameter);

    traySlotRects.clear();
    final trayLeft = hammerButtonRect.right + 10.0;
    final trayRight = compassButtonRect.left - 10.0;
    final trayTotalWidth = trayRight - trayLeft;
    final singleTrayWidth = trayTotalWidth / 3.0;
    final trayHeight = math.min(zoneDRect.height * 0.78, 76.0);
    final trayTop = zoneDRect.top + (zoneDRect.height - trayHeight) / 2;

    for (int i = 0; i < 3; i++) {
      traySlotRects.add(Rect.fromLTWH(
        trayLeft + i * singleTrayWidth + 4,
        trayTop,
        singleTrayWidth - 8,
        trayHeight,
      ));
    }
  }

  /// Chuyển đổi tọa độ ngón tay (có áp dụng touchOffsetY) sang chỉ số ô (row, col) trên bàn cờ
  PointInt? getGridCellFromTouch(Offset rawTouchPoint) {
    final effectivePoint = Offset(rawTouchPoint.dx, rawTouchPoint.dy + touchOffsetY);

    if (!innerGridRect.contains(effectivePoint)) {
      return null;
    }

    final col = ((effectivePoint.dx - innerGridRect.left) / cellSize).floor();
    final row = ((effectivePoint.dy - innerGridRect.top) / cellSize).floor();

    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      return PointInt(row, col);
    }
    return null;
  }

  /// Tính tâm của một ô (row, col) trên màn hình
  Offset getCellCenter(int row, int col) {
    return Offset(
      innerGridRect.left + (col + 0.5) * cellSize,
      innerGridRect.top + (row + 0.5) * cellSize,
    );
  }

  /// Tính tâm của một ghế chờ trên Holding Dock
  Offset getDockSlotCenter(int slotIndex) {
    if (slotIndex >= 0 && slotIndex < dockSlotRects.length) {
      return dockSlotRects[slotIndex].center;
    }
    return zoneBRect.center;
  }

  /// Tọa độ cửa sổ xe buýt đón khách ở Zone A
  Offset get activeBusDoorCenter {
    return Offset(zoneARect.left + zoneARect.width * 0.40, zoneARect.top + zoneARect.height * 0.60);
  }
}

