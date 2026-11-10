import 'dart:math' as math;
import '../models/enums.dart';
import '../models/grid_cell_data.dart';
import '../models/polyomino_shape.dart';
import '../core/game_event_bus.dart';

const int kGridSize = 8;

class LineEvaluationResult {
  final List<int> fullRows;
  final List<int> fullCols;
  final List<PointInt> clearedPoints;
  final int comboMultiplier;

  const LineEvaluationResult({
    required this.fullRows,
    required this.fullCols,
    required this.clearedPoints,
    required this.comboMultiplier,
  });

  int get totalLines => fullRows.length + fullCols.length;
}

class FreedPetInfo {
  final int row;
  final int col;
  final PetColor color;

  const FreedPetInfo({
    required this.row,
    required this.col,
    required this.color,
  });
}

class GridEngine {
  final List<List<GridCellData>> cells;
  int consecutiveTurnsWithoutClears = 0;

  GridEngine()
      : cells = List.generate(
          kGridSize,
          (r) => List.generate(
            kGridSize,
            (c) => GridCellData(row: r, col: c),
          ),
        );

  void resetGrid() {
    consecutiveTurnsWithoutClears = 0;
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        cells[r][c].reset();
      }
    }
  }

  void loadInitialLayout(List<GridCellData> initialCells) {
    resetGrid();
    for (final item in initialCells) {
      if (item.row >= 0 && item.row < kGridSize && item.col >= 0 && item.col < kGridSize) {
        cells[item.row][item.col] = item.clone();
      }
    }
  }

  /// Kiểm tra xem khối gạch có thể đặt tại (startRow, startCol) không
  bool canPlacePolyomino(PolyominoShape shape, int startRow, int startCol) {
    for (final tile in shape.tiles) {
      final targetR = startRow + tile.r;
      final targetC = startCol + tile.c;

      // 1. Kiểm tra biên bàn cờ 8x8
      if (targetR < 0 || targetR >= kGridSize || targetC < 0 || targetC >= kGridSize) {
        return false;
      }

      final cell = cells[targetR][targetC];

      // 2. Ô bị khóa (do bom nổ hoặc địa hình dị hình)
      if (cell.isLocked) {
        return false;
      }

      // 3. Ô đã có thú hoặc đá tảng
      if (cell.petColor != null || cell.hazard == HazardType.stone) {
        return false;
      }
    }

    return true;
  }

  /// Đặt khối gạch vào bàn cờ 8x8
  bool placePolyomino(PolyominoShape shape, int startRow, int startCol) {
    if (!canPlacePolyomino(shape, startRow, startCol)) {
      return false;
    }

    for (final tile in shape.tiles) {
      final targetR = startRow + tile.r;
      final targetC = startCol + tile.c;
      final cell = cells[targetR][targetC];

      cell.petColor = tile.petColor;
      cell.hazard = tile.hazard;
      cell.animScale = 1.18; // Hiệu ứng đàn hồi nảy nhẹ (Squash & Stretch)
      if (tile.hazard == HazardType.ice) {
        cell.iceLayer = 2;
      } else if (tile.hazard == HazardType.bomb) {
        cell.bombTurns = 6;
      }
    }

    return true;
  }

  /// Quét nổ đồng thời tất cả các hàng ngang và cột dọc đã đầy
  LineEvaluationResult evaluateLines() {
    final List<int> fullRows = [];
    final List<int> fullCols = [];
    final Set<String> clearedKeys = {};

    // 1. Quét 8 hàng ngang
    for (int r = 0; r < kGridSize; r++) {
      bool isFull = true;
      for (int c = 0; c < kGridSize; c++) {
        final cell = cells[r][c];
        if (!cell.hasContent || cell.isLocked) {
          isFull = false;
          break;
        }
      }
      if (isFull) {
        fullRows.add(r);
        for (int c = 0; c < kGridSize; c++) {
          clearedKeys.add('$r,$c');
        }
      }
    }

    // 2. Quét 8 cột dọc
    for (int c = 0; c < kGridSize; c++) {
      bool isFull = true;
      for (int r = 0; r < kGridSize; r++) {
        final cell = cells[r][c];
        if (!cell.hasContent || cell.isLocked) {
          isFull = false;
          break;
        }
      }
      if (isFull) {
        fullCols.add(c);
        for (int r = 0; r < kGridSize; r++) {
          clearedKeys.add('$r,$c');
        }
      }
    }

    final List<PointInt> points = [];
    for (final key in clearedKeys) {
      final parts = key.split(',');
      points.add(PointInt(int.parse(parts[0]), int.parse(parts[1])));
    }

    final total = fullRows.length + fullCols.length;
    int combo = 1;
    if (total >= 4) {
      combo = 4;
    } else if (total == 3) {
      combo = 3;
    } else if (total == 2) {
      combo = 2;
    }

    if (total > 0) {
      consecutiveTurnsWithoutClears = 0;
    } else {
      consecutiveTurnsWithoutClears++;
    }

    return LineEvaluationResult(
      fullRows: fullRows,
      fullCols: fullCols,
      clearedPoints: points,
      comboMultiplier: combo,
    );
  }

  /// Xử lý thực thi nổ hàng: phá băng, gỡ bom, cắt dây leo, thu thập thú cưng
  List<FreedPetInfo> executeLineClear(List<PointInt> points) {
    final List<FreedPetInfo> freed = [];

    for (final pt in points) {
      final cell = cells[pt.r][pt.c];

      // Đá tảng không thể nổ bằng hàng bình thường
      if (cell.hazard == HazardType.stone) {
        continue;
      }

      // Xử lý Băng Giá (ICE 2 lớp):
      // Lần nổ 1: nứt băng (lớp 2 -> 1). Thú vẫn còn kẹt bên trong!
      if (cell.hazard == HazardType.ice && cell.iceLayer > 1) {
        cell.iceLayer = 1;
        GameEventBus.instance.fire(HazardUpdatedEvent(
          hazard: HazardType.ice,
          row: pt.r,
          col: pt.c,
          details: 1,
        ));
        continue;
      }

      // Lần nổ 2: tan băng hoàn toàn (lớp 1 -> 0)
      if (cell.hazard == HazardType.ice && cell.iceLayer == 1) {
        cell.hazard = null;
        cell.iceLayer = 0;
      }

      // Gỡ Bom khi dòng có bom nổ
      if (cell.hazard == HazardType.bomb) {
        cell.hazard = null;
        cell.bombTurns = 0;
      }

      // Cắt Dây Leo
      if (cell.hazard == HazardType.vine) {
        cell.hazard = null;
      }

      // Giải phóng thú cưng nếu có
      if (cell.petColor != null) {
        freed.add(FreedPetInfo(
          row: pt.r,
          col: pt.c,
          color: cell.petColor!,
        ));
        cell.petColor = null;
      }
    }

    return freed;
  }

  /// Búa Rèn Lửa: Đập nát vùng 3x3 quanh (centerRow, centerCol), giải phóng toàn bộ thú cưng
  List<FreedPetInfo> destroy3x3Area(int centerRow, int centerCol) {
    final List<FreedPetInfo> freed = [];

    final minR = math.max(0, centerRow - 1);
    final maxR = math.min(kGridSize - 1, centerRow + 1);
    final minC = math.max(0, centerCol - 1);
    final maxC = math.min(kGridSize - 1, centerCol + 1);

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        final cell = cells[r][c];

        if (cell.petColor != null) {
          freed.add(FreedPetInfo(row: r, col: c, color: cell.petColor!));
          cell.petColor = null;
        }

        cell.hazard = null;
        cell.iceLayer = 0;
        cell.bombTurns = 0;
        cell.isLocked = false;
        cell.animScale = 0.85;
      }
    }

    return freed;
  }

  /// Cập nhật các ô đặc biệt sau mỗi lượt đặt gạch:
  /// 1. Giảm đếm ngược của Bom. Nếu về 0 -> nổ khóa vùng 3x3!
  /// 2. Lan Dây Leo sang 1 ô trống cạnh bên nếu 2 lượt liên tiếp không nổ hàng.
  void updateHazards() {
    // 1. Đếm ngược Bom
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        final cell = cells[r][c];
        if (cell.hazard == HazardType.bomb && cell.bombTurns > 0) {
          cell.bombTurns--;
          GameEventBus.instance.fire(HazardUpdatedEvent(
            hazard: HazardType.bomb,
            row: r,
            col: c,
            details: cell.bombTurns,
          ));

          if (cell.bombTurns <= 0) {
            // Bom phát nổ! Khóa vĩnh viễn vùng 3x3 xung quanh
            _explodeBombAt(r, c);
          }
        }
      }
    }

    // 2. Dây leo lan truyền nếu 2 lượt không phá hàng
    if (consecutiveTurnsWithoutClears >= 2) {
      final List<PointInt> vineSources = [];
      for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
          if (cells[r][c].hazard == HazardType.vine) {
            vineSources.add(PointInt(r, c));
          }
        }
      }

      if (vineSources.isNotEmpty) {
        final random = math.Random();
        final src = vineSources[random.nextInt(vineSources.length)];
        final neighbors = [
          PointInt(src.r - 1, src.c),
          PointInt(src.r + 1, src.c),
          PointInt(src.r, src.c - 1),
          PointInt(src.r, src.c + 1),
        ].where((p) => p.r >= 0 && p.r < kGridSize && p.c >= 0 && p.c < kGridSize).toList();

        final emptyNeighbors = neighbors.where((p) {
          final cell = cells[p.r][p.c];
          return cell.hazard == null && !cell.isLocked;
        }).toList();

        if (emptyNeighbors.isNotEmpty) {
          final target = emptyNeighbors[random.nextInt(emptyNeighbors.length)];
          cells[target.r][target.c].hazard = HazardType.vine;
          GameEventBus.instance.fire(VineSpreadEvent(
            fromRow: src.r,
            fromCol: src.c,
            toRow: target.r,
            toCol: target.c,
          ));
          consecutiveTurnsWithoutClears = 0;
        }
      }
    }
  }

  void _explodeBombAt(int centerRow, int centerCol) {
    final List<PointInt> affected = [];
    final minR = math.max(0, centerRow - 1);
    final maxR = math.min(kGridSize - 1, centerRow + 1);
    final minC = math.max(0, centerCol - 1);
    final maxC = math.min(kGridSize - 1, centerCol + 1);

    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        final cell = cells[r][c];
        cell.isLocked = true;
        cell.petColor = null;
        cell.hazard = null;
        affected.add(PointInt(r, c));
      }
    }

    GameEventBus.instance.fire(BombExplodedEvent(
      centerRow: centerRow,
      centerCol: centerCol,
      affected: affected,
    ));
  }

  /// Kiểm tra xem còn nước đi hợp lệ nào cho các khối gạch trong khay không
  bool hasValidMoveForShapes(List<PolyominoShape> shapes) {
    if (shapes.isEmpty) return true;

    for (final shape in shapes) {
      for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
          if (canPlacePolyomino(shape, r, c)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  int get emptyCellCount {
    int count = 0;
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        if (cells[r][c].isEmpty) {
          count++;
        }
      }
    }
    return count;
  }
}

