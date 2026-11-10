import 'dart:math' as math;
import '../models/enums.dart';
import '../models/polyomino_shape.dart';
import '../models/bus_data.dart';

class SmartSpawner {
  final List<PolyominoShape?> nextShapes = [null, null, null];
  int _counter = 0;
  final math.Random _random = math.Random();

  List<PolyominoShape> get activeShapes =>
      nextShapes.whereType<PolyominoShape>().toList();

  bool replenishIfNeeded({
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
    required int emptyBoardCells,
  }) {
    if (nextShapes.every((s) => s == null)) {
      generateNewBatch(
        availableColors: availableColors,
        activeBus: activeBus,
        nextBus: nextBus,
        emptyBoardCells: emptyBoardCells,
      );
      return true;
    }
    return false;
  }

  /// Sinh một đợt 3 khối gạch mới:
  /// - Ít nhất 45% ô gạch trùng màu với activeBus hoặc nextBus
  /// - Kích hoạt Mercy Rule (tăng tỷ lệ khối 1x1, 1x2) khi bàn cờ đầy trên 75% (<= 16 ô trống)
  void generateNewBatch({
    required List<PetColor> availableColors,
    required BusData? activeBus,
    required BusData? nextBus,
    required int emptyBoardCells,
  }) {
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
      nextShapes[i] = _createSmartShape(
        availableColors: availableColors,
        priorityColors: priorityColors,
        isMercy: isMercyRuleActive,
      );
    }
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

    // 2. Xác định màu sắc: đảm bảo >= 45% tỷ lệ trùng màu với xe đang đỗ / xe chờ
    final PetColor shapeColor;
    if (priorityColors.isNotEmpty && _random.nextDouble() < 0.48) {
      shapeColor = priorityColors[_random.nextInt(priorityColors.length)];
    } else {
      shapeColor = availableColors[_random.nextInt(availableColors.length)];
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
    final shape = nextShapes[slotIndex];
    nextShapes[slotIndex] = null;
    return shape;
  }

  void returnShape(int slotIndex, PolyominoShape shape) {
    if (slotIndex >= 0 && slotIndex < 3) {
      nextShapes[slotIndex] = shape;
    }
  }

  /// La Bàn Gió: Xoay 90 độ tất cả khối gạch đang có trong khay Next
  void rotateAllShapes() {
    for (int i = 0; i < 3; i++) {
      if (nextShapes[i] != null) {
        nextShapes[i] = nextShapes[i]!.rotateClockwise();
      }
    }
  }
}

