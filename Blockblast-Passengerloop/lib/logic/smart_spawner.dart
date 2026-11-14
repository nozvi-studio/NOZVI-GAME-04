import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/enums.dart';
import '../models/polyomino_shape.dart';
import '../models/bus_data.dart';
import '../core/game_event_bus.dart';
import 'grid_engine.dart';

class SmartSpawner extends ChangeNotifier {
  final List<PolyominoShape?> traySlots = List<PolyominoShape?>.filled(3, null);
  int _counter = 0;
  int batchId = 0;
  final math.Random _random = math.Random();

  /// Alias tương thích ngược cho các module cũ
  List<PolyominoShape?> get nextShapes => traySlots;

  List<PolyominoShape> get activeShapes =>
      traySlots.whereType<PolyominoShape>().toList();

  /// Kiểm tra toàn bộ 3 ô khay Next đã trống hết chưa (TUYỆT ĐỐI không dùng .isEmpty)
  bool get isTrayEmpty => traySlots.every((element) => element == null);

  void notifyTrayChanged() {
    notifyListeners();
  }

  /// Xóa khối gạch khỏi ô khay ngay khi đặt thành công xuống bàn cờ
  void clearSlot(int slotIndex) {
    if (slotIndex >= 0 && slotIndex < traySlots.length) {
      traySlots[slotIndex] = null;
      notifyListeners();
    }
  }

  bool replenishIfNeeded({
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
    required int emptyBoardCells,
  }) {
    final bool isEmpty = traySlots.every((element) => element == null);
    if (isEmpty) {
      refillTray(
        availableColors: availableColors,
        activeBus: activeBus,
        nextBus: nextBus,
        emptyBoardCells: emptyBoardCells,
      );
      return true;
    }
    return false;
  }

  /// Nạp mới toàn bộ 3 khối gạch đảm bảo ít nhất 1 khối đặt vừa vào bàn cờ 8x8 hiện tại
  void refillTrayGuaranteedPlayable({
    required GridEngine gridEngine,
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
  }) {
    final List<PetColor> priorityColors = [];
    if (activeBus != null && !priorityColors.contains(activeBus.color)) {
      priorityColors.add(activeBus.color);
    }
    if (nextBus != null && !priorityColors.contains(nextBus.color)) {
      priorityColors.add(nextBus.color);
    }

    final int emptyCells = gridEngine.emptyCellCount;
    final bool isMercyRuleActive = emptyCells <= 16;

    for (int i = 0; i < 3; i++) {
      traySlots[i] = _createSmartShape(
        availableColors: availableColors,
        priorityColors: priorityColors,
        isMercy: isMercyRuleActive,
      );
    }

    // Kiểm tra chống kẹt oan: Nếu cả 3 khối đều không có chỗ đặt trên gridEngine -> ép slot 0 thành khối nhỏ vừa vặn!
    if (!gridEngine.hasValidMoveForShapes(activeShapes) && emptyCells > 0) {
      final sortedTemplates = List<ShapeTemplate>.from(kPolyominoTemplates)
        ..sort((a, b) => a.offsets.length.compareTo(b.offsets.length));

      final PetColor fallbackColor = priorityColors.isNotEmpty
          ? priorityColors.first
          : availableColors[_random.nextInt(availableColors.length)];

      for (final template in sortedTemplates) {
        final tiles = template.offsets
            .map((pt) => ShapeTile(r: pt.r, c: pt.c, petColor: fallbackColor))
            .toList();
        final int maxR = tiles.map((t) => t.r).reduce(math.max);
        final int maxC = tiles.map((t) => t.c).reduce(math.max);
        _counter++;
        final candidate = PolyominoShape(
          id: 'safe_${_counter}_${DateTime.now().millisecondsSinceEpoch}',
          name: template.name,
          tiles: tiles,
          width: maxC + 1,
          height: maxR + 1,
        );

        if (gridEngine.hasValidMoveForShapes([candidate])) {
          traySlots[0] = candidate;
          break;
        }
      }
    }

    batchId++;
    GameEventBus.instance.fire(TrayRefilledEvent(batchId: batchId));
    notifyListeners();
  }

  /// Nạp mới toàn bộ 3 khối gạch vào khay Next và phát sự kiện cho hiệu ứng scale 0.0 -> 1.0
  void refillTray({
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
    required int emptyBoardCells,
    GridEngine? gridEngine,
  }) {
    if (gridEngine != null) {
      refillTrayGuaranteedPlayable(
        gridEngine: gridEngine,
        availableColors: availableColors,
        activeBus: activeBus,
        nextBus: nextBus,
      );
      return;
    }

    final List<PetColor> priorityColors = [];
    if (activeBus != null && !priorityColors.contains(activeBus.color)) {
      priorityColors.add(activeBus.color);
    }
    if (nextBus != null && !priorityColors.contains(nextBus.color)) {
      priorityColors.add(nextBus.color);
    }

    // Mercy Rule: Bàn cờ 64 ô, nếu còn <= 16 ô trống tức là đã đầy >= 75%
    final bool isMercyRuleActive = emptyBoardCells <= 16;

    for (int i = 0; i < 3; i++) {
      traySlots[i] = _createSmartShape(
        availableColors: availableColors,
        priorityColors: priorityColors,
        isMercy: isMercyRuleActive,
      );
    }

    batchId++;
    GameEventBus.instance.fire(TrayRefilledEvent(batchId: batchId));
    notifyListeners();
  }

  /// Sinh một đợt 3 khối gạch mới
  void generateNewBatch({
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
    required int emptyBoardCells,
  }) {
    refillTray(
      availableColors: availableColors,
      activeBus: activeBus,
      nextBus: nextBus,
      emptyBoardCells: emptyBoardCells,
    );
  }

  PolyominoShape _createSmartShape({
    required List<PetColor> availableColors,
    required List<PetColor> priorityColors,
    required bool isMercy,
  }) {
    _counter++;

    // 1. Chọn khuôn mẫu hình dạng
    final ShapeTemplate template;
    if (isMercy && _random.nextDouble() < 0.70) {
      // Ưu tiên khối nhỏ 1x1, 1x2, 2x2 khi kích hoạt Mercy Rule
      final smallTemplates = kPolyominoTemplates.where((t) => t.offsets.length <= 3).toList();
      template = smallTemplates[_random.nextInt(smallTemplates.length)];
    } else {
      template = kPolyominoTemplates[_random.nextInt(kPolyominoTemplates.length)];
    }

    // 2. Xác định màu sắc chuẩn Bus Solver: ưu tiên cao cho Active Bus và Next Bus (72%)
    final PetColor shapeColor;
    if (priorityColors.isNotEmpty && _random.nextDouble() < 0.72) {
      // Ưu tiên cao nhất cho xe đang đỗ tại bến để người chơi giải quyết mục tiêu đón xe
      if (priorityColors.length >= 2 && _random.nextDouble() < 0.30) {
        shapeColor = priorityColors[1]; // Next Bus
      } else {
        shapeColor = priorityColors[0]; // Active Bus
      }
    } else if (availableColors.isNotEmpty) {
      shapeColor = availableColors[_random.nextInt(availableColors.length)];
    } else {
      shapeColor = priorityColors.isNotEmpty ? priorityColors.first : PetColor.red;
    }

    final tiles = template.offsets.map((pt) {
      return ShapeTile(
        r: pt.r,
        c: pt.c,
        petColor: shapeColor,
      );
    }).toList();

    int maxR = tiles.map((t) => t.r).reduce(math.max);
    int maxC = tiles.map((t) => t.c).reduce(math.max);

    return PolyominoShape(
      id: 'shape_${_counter}_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      tiles: tiles,
      width: maxC + 1,
      height: maxR + 1,
    );
  }

  PolyominoShape? takeShape(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= 3) return null;
    final shape = traySlots[slotIndex];
    traySlots[slotIndex] = null;
    notifyListeners();
    return shape;
  }

  void returnShape(int slotIndex, PolyominoShape shape) {
    if (slotIndex >= 0 && slotIndex < 3) {
      traySlots[slotIndex] = shape;
      notifyListeners();
    }
  }

  /// La Bàn Gió: Xoay 90 độ tất cả khối gạch đang có trong khay Next
  void rotateAllShapes() {
    for (int i = 0; i < 3; i++) {
      if (traySlots[i] != null) {
        traySlots[i] = traySlots[i]!.rotateClockwise();
      }
    }
    notifyListeners();
  }
}
