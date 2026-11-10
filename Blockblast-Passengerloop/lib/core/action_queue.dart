import 'dart:async';
import '../models/enums.dart';
import '../models/polyomino_shape.dart';
import '../logic/grid_engine.dart';
import '../logic/bus_station_manager.dart';
import '../logic/smart_spawner.dart';
import 'game_event_bus.dart';

class ActionQueueExecutionResult {
  final bool gameWon;
  final bool gameLost;
  final String? loseReason;
  final int scoreGained;
  final int comboMultiplier;

  const ActionQueueExecutionResult({
    this.gameWon = false,
    this.gameLost = false,
    this.loseReason,
    this.scoreGained = 0,
    this.comboMultiplier = 1,
  });
}

class ActionQueue {
  final GridEngine gridEngine;
  final BusStationManager busStation;
  final SmartSpawner smartSpawner;

  bool _isProcessing = false;
  int currentScore = 0;
  int currentLevel = 1;
  int hammerCharge = 0;
  final int hammerMaxCharge = 3;
  int compassCharge = 0;
  final int compassMaxCharge = 2;

  ActionQueue({
    required this.gridEngine,
    required this.busStation,
    required this.smartSpawner,
  });

  bool get isLocked => _isProcessing;

  void resetScore(int level) {
    currentScore = 0;
    currentLevel = level;
    hammerCharge = 0;
    compassCharge = 0;
    _notifyRelicStatus();
  }

  void setInitialCharges({int hammer = 0, int compass = 0}) {
    hammerCharge = hammer.clamp(0, hammerMaxCharge);
    compassCharge = compass.clamp(0, compassMaxCharge);
    _notifyRelicStatus();
  }

  /// Thực thi chuỗi 7 bước tuần tự bất đồng bộ khi người chơi thả khối gạch
  Future<ActionQueueExecutionResult> executeBlockDrop({
    required PolyominoShape shape,
    required int targetRow,
    required int targetCol,
    required List<PetColor> availableColors,
  }) async {
    if (_isProcessing) {
      return const ActionQueueExecutionResult();
    }

    _isProcessing = true;
    GameEventBus.instance.fire(InputLockEvent(locked: true, reason: 'action_queue'));

    int turnScore = 0;
    int turnCombo = 1;
    bool won = false;
    bool lost = false;
    String? loseReason;

    try {
      // BƯỚC 1: PLACE_BLOCK - Gắn khối gạch vào bàn cờ 8x8
      final placed = gridEngine.placePolyomino(shape, targetRow, targetCol);
      if (!placed) {
        throw Exception('Không thể đặt khối gạch tại ($targetRow, $targetCol)');
      }
      GameEventBus.instance.fire(BlockPlacedEvent(shape: shape, row: targetRow, col: targetCol));
      final tileScore = shape.tiles.length * 10;
      _addScore(tileScore, 1);
      turnScore += tileScore;
      await Future.delayed(const Duration(milliseconds: 140));

      // BƯỚC 2: EVALUATE_LINES - Quét nổ đồng thời các hàng ngang & cột dọc
      final lineResult = gridEngine.evaluateLines();
      turnCombo = lineResult.comboMultiplier;

      if (lineResult.totalLines > 0) {
        GameEventBus.instance.fire(LinesClearedEvent(
          rows: lineResult.fullRows,
          cols: lineResult.fullCols,
          comboMultiplier: lineResult.comboMultiplier,
          clearedPoints: lineResult.clearedPoints,
        ));

        final lineScore = lineResult.totalLines * 100 * lineResult.comboMultiplier;
        _addScore(lineScore, lineResult.comboMultiplier);
        turnScore += lineScore;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // BƯỚC 3: EXTRACT_PASSENGERS - Thu thập thú cưng và phân loại ưu tiên
      if (lineResult.clearedPoints.isNotEmpty) {
        final freedPets = gridEngine.executeLineClear(lineResult.clearedPoints);
        final extractResult = busStation.extractAndSortPassengers(freedPets);

        if (extractResult.items.isNotEmpty) {
          GameEventBus.instance.fire(PassengersExtractedEvent(passengers: extractResult.items));
          final passScore = extractResult.items.length * 50 * turnCombo;
          _addScore(passScore, turnCombo);
          turnScore += passScore;
          await Future.delayed(const Duration(milliseconds: 380));
        }

        // BƯỚC 4: BOARD_AND_DOCK - Xe đầy sẽ xuất bến, gọi khách từ ghế chờ
        if (extractResult.dispatchedBuses.isNotEmpty) {
          for (final _ in extractResult.dispatchedBuses) {
            _addScore(500, 1);
            _chargeCompass(1);
          }
          await Future.delayed(const Duration(milliseconds: 260));
        }

        if (extractResult.dockOverflow) {
          lost = true;
          loseReason = 'DOCK_OVERFLOW';
        }
      }

      // Bổ sung khối gạch mới vào khay Next nếu cả 3 khối đã được sử dụng
      smartSpawner.replenishIfNeeded(
        availableColors: availableColors,
        activeBus: busStation.activeBus,
        nextBus: busStation.nextBus,
        emptyBoardCells: gridEngine.emptyCellCount,
      );

      // BƯỚC 5: UPDATE_HAZARDS - Đếm ngược Bom và lan Dây Leo
      gridEngine.updateHazards();
      await Future.delayed(const Duration(milliseconds: 120));

      // BƯỚC 6: CHECK_RELICS - Sạc Búa Rèn Lửa khi có hàng nổ
      if (lineResult.totalLines > 0) {
        _chargeHammer(lineResult.totalLines);
      }

      // BƯỚC 7: CHECK_GAME_STATE - Kiểm tra Thắng / Thua
      if (lost) {
        GameEventBus.instance.fire(GameOverEvent(
          reason: loseReason ?? 'DOCK_OVERFLOW',
          level: currentLevel,
          score: currentScore,
        ));
      } else if (busStation.allBusesCleared) {
        won = true;
        final stars = _calculateStars();
        GameEventBus.instance.fire(GameWinEvent(
          level: currentLevel,
          score: currentScore,
          stars: stars,
        ));
      } else {
        // Kiểm tra xem còn nước đi hợp lệ nào không
        final remaining = smartSpawner.activeShapes;
        final hasMoves = gridEngine.hasValidMoveForShapes(remaining);
        if (!hasMoves && remaining.isNotEmpty) {
          lost = true;
          loseReason = 'NO_VALID_MOVES';
          GameEventBus.instance.fire(GameOverEvent(
            reason: 'NO_VALID_MOVES',
            level: currentLevel,
            score: currentScore,
          ));
        }
      }
    } finally {
      _isProcessing = false;
      GameEventBus.instance.fire(InputLockEvent(locked: false));
    }

    return ActionQueueExecutionResult(
      gameWon: won,
      gameLost: lost,
      loseReason: loseReason,
      scoreGained: turnScore,
      comboMultiplier: turnCombo,
    );
  }

  /// Kích hoạt Búa Rèn Lửa: Đập nát vùng 3x3 quanh (row, col)
  Future<void> executeHammerSmash({
    required int centerRow,
    required int centerCol,
    required List<PetColor> availableColors,
  }) async {
    if (_isProcessing || hammerCharge < hammerMaxCharge) return;

    _isProcessing = true;
    GameEventBus.instance.fire(InputLockEvent(locked: true, reason: 'hammer_smash'));
    hammerCharge = 0;
    _notifyRelicStatus();
    GameEventBus.instance.fire(RelicUsedEvent(relic: RelicType.hammer));

    try {
      final freedPets = gridEngine.destroy3x3Area(centerRow, centerCol);
      final extractResult = busStation.extractAndSortPassengers(freedPets);

      if (extractResult.items.isNotEmpty) {
        GameEventBus.instance.fire(PassengersExtractedEvent(passengers: extractResult.items));
        _addScore(extractResult.items.length * 60, 1);
        await Future.delayed(const Duration(milliseconds: 380));
      }

      if (extractResult.dispatchedBuses.isNotEmpty) {
        for (final _ in extractResult.dispatchedBuses) {
          _addScore(500, 1);
          _chargeCompass(1);
        }
      }

      smartSpawner.replenishIfNeeded(
        availableColors: availableColors,
        activeBus: busStation.activeBus,
        nextBus: busStation.nextBus,
        emptyBoardCells: gridEngine.emptyCellCount,
      );

      // Kiểm tra thắng
      if (busStation.allBusesCleared) {
        final stars = _calculateStars();
        GameEventBus.instance.fire(GameWinEvent(
          level: currentLevel,
          score: currentScore,
          stars: stars,
        ));
      }
    } finally {
      _isProcessing = false;
      GameEventBus.instance.fire(InputLockEvent(locked: false));
    }
  }

  /// Kích hoạt La Bàn Gió: Xoay 90 độ cả 3 khối trong khay Next
  bool executeWindCompass() {
    if (compassCharge < compassMaxCharge) return false;

    compassCharge = 0;
    _notifyRelicStatus();
    smartSpawner.rotateAllShapes();
    GameEventBus.instance.fire(RelicUsedEvent(relic: RelicType.compass));
    return true;
  }

  void _chargeHammer(int lines) {
    if (hammerCharge < hammerMaxCharge) {
      hammerCharge = (hammerCharge + lines).clamp(0, hammerMaxCharge);
      _notifyRelicStatus();
    }
  }

  void _chargeCompass(int buses) {
    if (compassCharge < compassMaxCharge) {
      compassCharge = (compassCharge + buses).clamp(0, compassMaxCharge);
      _notifyRelicStatus();
    }
  }

  void _notifyRelicStatus() {
    GameEventBus.instance.fire(RelicChargedEvent(
      relic: RelicType.hammer,
      current: hammerCharge,
      max: hammerMaxCharge,
      isReady: hammerCharge >= hammerMaxCharge,
    ));
    GameEventBus.instance.fire(RelicChargedEvent(
      relic: RelicType.compass,
      current: compassCharge,
      max: compassMaxCharge,
      isReady: compassCharge >= compassMaxCharge,
    ));
  }

  void _addScore(int delta, int combo) {
    final finalDelta = delta * combo;
    currentScore += finalDelta;
    GameEventBus.instance.fire(ScoreChangedEvent(
      score: currentScore,
      delta: finalDelta,
      combo: combo,
    ));
  }

  int _calculateStars() {
    if (currentScore >= 3500) return 3;
    if (currentScore >= 2000) return 2;
    return 1;
  }
}
