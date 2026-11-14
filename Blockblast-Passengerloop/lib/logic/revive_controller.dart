import '../models/enums.dart';
import '../models/polyomino_shape.dart';
import 'grid_engine.dart';
import 'bus_station_manager.dart';
import 'smart_spawner.dart';

enum ReviveType {
  dockOverflow,
  gridLock,
}

class ReviveExecutionResult {
  final bool success;
  final ReviveType type;
  final String message;
  final List<FreedPetInfo> freedPets;

  const ReviveExecutionResult({
    required this.success,
    required this.type,
    required this.message,
    this.freedPets = const [],
  });
}

/// Điều khiển cơ chế hồi sinh cứu thua trong trận (Pinch-Point Revive)
class ReviveController {
  bool hasUsedReviveInMatch = false;

  void reset() {
    hasUsedReviveInMatch = false;
  }

  /// Thực hiện cứu thua khi thua do Tràn ghế chờ (Dock Overflow):
  /// - Gọi trực thăng bốc 3 thú cưng khỏi ghế chờ
  /// - Mở rộng thêm 1 ghế VIP cho ván đấu hiện tại
  ReviveExecutionResult executeDockOverflowRevive({
    required BusStationManager busStation,
  }) {
    if (hasUsedReviveInMatch) {
      return const ReviveExecutionResult(
        success: false,
        type: ReviveType.dockOverflow,
        message: 'Đã sử dụng lượt hồi sinh trong ván này!',
      );
    }

    hasUsedReviveInMatch = true;

    // 1. Trực thăng bốc 3 thú cưng khỏi ghế chờ
    final rescued = busStation.rescuePetsFromDock(3);

    // 2. Mở thêm 1 ghế VIP vĩnh viễn cho ván đấu
    busStation.expandDockByOne();

    return ReviveExecutionResult(
      success: true,
      type: ReviveType.dockOverflow,
      message: '🚁 Trực thăng đã giải cứu ${rescued.length} thú cưng và mở thêm 1 ghế VIP!',
    );
  }

  /// Thực hiện cứu thua khi thua do Hết chỗ đặt gạch (Grid Lock):
  /// - Quét và phá sạch 2 hàng đông gạch nhất trên bàn cờ 8x8
  /// - Biến 3 khối gạch ở khay Next thành 3 khối đơn 1x1 trùng màu xe buýt hiện tại
  ReviveExecutionResult executeGridLockRevive({
    required GridEngine gridEngine,
    required SmartSpawner smartSpawner,
    required PetColor activeBusColor,
  }) {
    if (hasUsedReviveInMatch) {
      return const ReviveExecutionResult(
        success: false,
        type: ReviveType.gridLock,
        message: 'Đã sử dụng lượt hồi sinh trong ván này!',
      );
    }

    hasUsedReviveInMatch = true;

    // 1. Tìm 2 hàng có nhiều ô bị chiếm nhất
    final rowOccupancy = <int, int>{};
    for (int r = 0; r < kGridSize; r++) {
      int count = 0;
      for (int c = 0; c < kGridSize; c++) {
        if (gridEngine.cells[r][c].hasContent) {
          count++;
        }
      }
      rowOccupancy[r] = count;
    }

    final sortedRows = rowOccupancy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rowsToClear = sortedRows.take(2).map((e) => e.key).toList();

    // 2. Phá sạch 2 hàng và thu thập thú cưng trên các ô đó
    final pointsToClear = <PointInt>[];
    for (final r in rowsToClear) {
      for (int c = 0; c < kGridSize; c++) {
        pointsToClear.add(PointInt(r, c));
      }
    }
    final freedPets = gridEngine.executeLineClear(pointsToClear);

    // 3. Biến 3 khối gạch ở khay Next thành 3 khối đơn 1x1 trùng màu xe buýt
    for (int i = 0; i < 3; i++) {
      smartSpawner.traySlots[i] = PolyominoShape(
        id: 'revive_dot_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: 'Revive 1x1',
        width: 1,
        height: 1,
        tiles: [
          ShapeTile(
            r: 0,
            c: 0,
            petColor: activeBusColor,
          ),
        ],
      );
    }
    smartSpawner.notifyTrayChanged();

    return ReviveExecutionResult(
      success: true,
      type: ReviveType.gridLock,
      message: '🚒 Đội cứu hộ đã dọn sạch 2 hàng gạch và cấp 3 khối 1x1 giải cứu!',
      freedPets: freedPets,
    );
  }
}
