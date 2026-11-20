import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/grid_cell_data.dart';
import '../models/polyomino_shape.dart';
import '../models/bus_data.dart';
import '../core/game_event_bus.dart';
import '../core/action_queue.dart';
import '../core/viewport_scaler.dart';
import '../core/pentatonic_audio_synth.dart';
import '../ui/painters/board_25d_painter.dart';
import '../ui/painters/bus_station_painter.dart';
import 'grid_engine.dart';
import 'bus_station_manager.dart';
import 'smart_spawner.dart';
import 'level_generator.dart';
import 'win_streak_manager.dart';
import 'revive_controller.dart';
import 'player_economy_service.dart';
import 'bus_rush_race_service.dart';
import '../ui/screens/pet_sanctuary_screen.dart';

/// Mô hình thú cưng đang bay theo đường cong Parabol lên cửa sổ xe buýt hoặc ghế gỗ Holding Dock
typedef FlyingPetAnim = FlyingPetArc;

/// Bộ điều khiển trận đấu thương mại chuẩn: kết nối Logic, Hiệu ứng Parabol, Highlight hàng nổ & Kinh tế
class CommercialGameController extends ChangeNotifier {
  final GridEngine gridEngine = GridEngine();
  final BusStationManager busStation = BusStationManager();
  final SmartSpawner smartSpawner = SmartSpawner();
  late final ActionQueue actionQueue;
  final ReviveController reviveController = ReviveController();

  late int currentLevel;
  late GameLevelConfig levelConfig;

  bool isTutorialActive = false;
  int tutorialStep = 1;
  bool isPaused = false;
  bool isHammerActive = false;

  final List<FlyingPetAnim> flyingPets = [];
  final List<ComboEffectData> floatingPopups = [];

  LinePreviewResult activeLinePreview = const LinePreviewResult();

  VoidCallback? onTrayRefilled;

  CommercialGameController() {
    actionQueue = ActionQueue(
      gridEngine: gridEngine,
      busStation: busStation,
      smartSpawner: smartSpawner,
    );
    smartSpawner.addListener(_onSpawnerUpdated);
  }

  void _onSpawnerUpdated() {
    notifyListeners();
  }

  void startLevel(int level) {
    currentLevel = level;
    isTutorialActive = (level == 0);
    tutorialStep = 1;
    isPaused = false;
    isHammerActive = false;
    activeLinePreview = const LinePreviewResult();
    flyingPets.clear();
    floatingPopups.clear();

    levelConfig = LevelGenerator.getLevel(level);
    reviveController.reset();
    actionQueue.resetScore(level);

    // Cộng dồn sạc Cổ vật khởi đầu từ Win Streak & Nâng cấp trong Shop
    final economy = PlayerEconomyService.instance;
    final streak = WinStreakManager.instance;
    final int startHammer = (streak.startingHammerCharges + economy.starterHammerCharges)
        .clamp(0, actionQueue.hammerMaxCharge);
    final int startCompass = (streak.startingCompassCharges + economy.starterCompassCharges)
        .clamp(0, actionQueue.compassMaxCharge);
    actionQueue.setInitialCharges(hammer: startHammer, compass: startCompass);

    // Sức chứa Holding Dock theo Super Bus Streak
    busStation.setDockCapacity(streak.dockCapacity);

    // Nạp danh sách xe buýt (Rainbow Express nếu đạt Streak Tier 3, trừ FTUE)
    final buses = levelConfig.buses.map((b) => b.clone()).toList();
    if (!isTutorialActive && buses.isNotEmpty && streak.firstBusIsRainbow) {
      buses[0] = BusData(
        id: buses[0].id,
        color: buses[0].color,
        name: '🌈 Rainbow Express',
        capacity: buses[0].capacity,
        currentPassengers: buses[0].currentPassengers,
        passengerPets: List<PetColor>.from(buses[0].passengerPets),
        isRainbow: true,
      );
    }
    busStation.initializeBuses(buses);
    gridEngine.loadInitialLayout(levelConfig.initialGrid);

    for (final slotIdx in levelConfig.lockedDockSlots) {
      if (slotIdx >= 0 && slotIdx < busStation.holdingDock.length) {
        busStation.holdingDock[slotIdx].isLocked = true;
      }
    }

    if (isTutorialActive) {
      setupTutorialStep(1);
    } else {
      _refillTrayGuaranteedPlayable();
    }

    notifyListeners();
  }

  /// Hàm nạp khay đảm bảo 100% có ít nhất 1 khối đặt vừa bàn cờ 8x8
  void _refillTrayGuaranteedPlayable() {
    smartSpawner.refillTrayGuaranteedPlayable(
      gridEngine: gridEngine,
      availableColors: levelConfig.availableColors,
      activeBus: busStation.activeBus,
      nextBus: busStation.nextBus,
    );
    onTrayRefilled?.call();
    notifyListeners();
  }

  void refillTrayGuaranteedPlayable() => _refillTrayGuaranteedPlayable();

  /// Kiểm tra hàng/cột sắp nổ khi đang kéo khối gạch trên bàn cờ 8x8
  LinePreviewResult previewLinesIfPlaced(PolyominoShape shape, int row, int col) {
    activeLinePreview = gridEngine.previewLinesIfPlaced(shape, row, col);
    return activeLinePreview;
  }

  void clearLinePreview() {
    activeLinePreview = const LinePreviewResult();
  }

  /// Đặt khối gạch tại (row, col) và xử lý toàn bộ 7 bước + refill tray nếu 3 ô đều null
  Future<ActionQueueExecutionResult> placeBlockAndProcess({
    required PolyominoShape shape,
    required int slotIndex,
    required int targetRow,
    required int targetCol,
  }) async {
    activeLinePreview = const LinePreviewResult();

    final result = await actionQueue.executeBlockDrop(
      shape: shape,
      slotIndex: slotIndex,
      targetRow: targetRow,
      targetCol: targetCol,
      availableColors: levelConfig.availableColors,
      isTutorialActive: isTutorialActive,
    );

    if (isTutorialActive) {
      if (tutorialStep == 1) {
        setupTutorialStep(2);
      } else if (tutorialStep == 2) {
        setupTutorialStep(3);
      } else {
        isTutorialActive = false;
        _refillTrayGuaranteedPlayable();
      }
    } else {
      // Bảo vệ kép: nếu cả 3 ô traySlots đều là null -> nạp lại ngay
      final bool isTrayEmpty = smartSpawner.traySlots.every((element) => element == null);
      if (isTrayEmpty) {
        _refillTrayGuaranteedPlayable();
      }
    }

    notifyListeners();
    return result;
  }

  Future<void> smashHammerAt(int row, int col) async {
    isHammerActive = false;
    PentatonicAudioSynth.instance.playHammerSmash();
    await actionQueue.executeHammerSmash(
      centerRow: row,
      centerCol: col,
      availableColors: levelConfig.availableColors,
    );
    notifyListeners();
  }

  bool activateCompass() {
    if (actionQueue.compassCharge < actionQueue.compassMaxCharge) return false;
    final ok = actionQueue.executeWindCompass();
    if (ok) {
      PentatonicAudioSynth.instance.playWindCompass();
      notifyListeners();
    }
    return ok;
  }

  void setupTutorialStep(int step) {
    tutorialStep = step;
    smartSpawner.traySlots[1] = null;
    smartSpawner.traySlots[2] = null;

    if (step == 1) {
      final cells = <GridCellData>[];
      for (int c = 0; c < 8; c++) {
        if (c != 3) {
          cells.add(GridCellData(row: 4, col: c, petColor: PetColor.red));
        }
      }
      gridEngine.loadInitialLayout(cells);
      smartSpawner.traySlots[0] = PolyominoShape(
        id: 'tut_dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.red)],
        width: 1,
        height: 1,
      );
    } else if (step == 2) {
      final cells = <GridCellData>[];
      for (int c = 0; c < 8; c++) {
        if (c != 2 && c != 3) {
          cells.add(GridCellData(row: 7, col: c, petColor: PetColor.red));
        }
      }
      gridEngine.loadInitialLayout(cells);
      smartSpawner.traySlots[0] = PolyominoShape(
        id: 'tut_line2',
        name: 'Line2_H',
        tiles: [
          const ShapeTile(r: 0, c: 0, petColor: PetColor.red),
          const ShapeTile(r: 0, c: 1, petColor: PetColor.red),
        ],
        width: 2,
        height: 1,
      );
    } else if (step == 3) {
      final cells = <GridCellData>[];
      for (int c = 0; c < 4; c++) {
        cells.add(GridCellData(row: 2, col: c, petColor: PetColor.red));
      }
      for (int c = 5; c < 8; c++) {
        cells.add(GridCellData(row: 2, col: c, petColor: PetColor.yellow));
      }
      gridEngine.loadInitialLayout(cells);
      smartSpawner.traySlots[0] = PolyominoShape(
        id: 'tut_cat_dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.yellow)],
        width: 1,
        height: 1,
      );
    }

    smartSpawner.notifyTrayChanged();
    onTrayRefilled?.call();
    notifyListeners();
  }

  /// Cho phép người chơi xem lại hướng dẫn (?) bất kỳ lúc nào hoặc tắt ngay bằng Skip
  void openTutorialOverlay() {
    isTutorialActive = true;
    setupTutorialStep(1);
    notifyListeners();
  }

  void skipTutorial() {
    isTutorialActive = false;
    _refillTrayGuaranteedPlayable();
    notifyListeners();
  }

  void spawnFlyingPets(List<PassengerExtractionItem> passengers, ViewportScaler scaler) {
    for (final p in passengers) {
      final Offset start = scaler.getCellCenter(p.fromRow, p.fromCol);
      final Offset end = p.destination == PassengerDestination.bus
          ? scaler.activeBusDoorCenter
          : scaler.getDockSlotCenter(p.dockSlotIndex ?? 0);

      flyingPets.add(FlyingPetAnim(
        id: p.id,
        color: p.color,
        start: start,
        end: end,
        progress: 0.0,
      ));
    }
    notifyListeners();
  }

  void spawnClearPopups(LinesClearedEvent event, ViewportScaler scaler) {
    final int row = event.rows.isNotEmpty ? event.rows.first : 3;
    final int col = event.cols.isNotEmpty ? event.cols.first : 3;
    final Offset center = scaler.getCellCenter(row, col);
    final int gained = event.totalClearedCountScore;

    floatingPopups.add(ComboEffectData(
      text: '+$gained',
      position: center + const Offset(0, -14),
      progress: 0.0,
      color: const Color(0xFF00E676),
      fontSize: 20.0,
    ));

    if (event.comboMultiplier >= 2) {
      floatingPopups.add(ComboEffectData(
        text: 'COMBO x${event.comboMultiplier}!',
        position: center + const Offset(0, -40),
        progress: 0.0,
        color: const Color(0xFFFFD84D),
        fontSize: 26.0,
      ));
    }
    notifyListeners();
  }

  Future<int> handleBusDispatched(BusData bus) async {
    await PetSanctuaryService.instance.recordBusDeparted(bus);
    await PlayerEconomyService.instance.syncCoinsFromPrefs();
    await BusRushRaceService.instance.recordPlayerBuses(1);
    return 25;
  }

  Future<int> handleMatchWin(int stars) async {
    await WinStreakManager.instance.recordWin();
    final int coinsReward = 50 + stars * 25 + WinStreakManager.instance.streakTier * 20;
    await PlayerEconomyService.instance.recordLevelVictory(currentLevel, stars, coinsReward);
    return coinsReward;
  }

  void tickAnimations(double flyingProgress) {
    for (int i = 0; i < flyingPets.length; i++) {
      flyingPets[i] = FlyingPetAnim(
        id: flyingPets[i].id,
        color: flyingPets[i].color,
        start: flyingPets[i].start,
        end: flyingPets[i].end,
        progress: flyingProgress,
      );
    }
    if (flyingProgress >= 1.0) {
      flyingPets.clear();
    }

    for (int i = 0; i < floatingPopups.length; i++) {
      final current = floatingPopups[i];
      floatingPopups[i] = ComboEffectData(
        text: current.text,
        position: current.position,
        progress: (current.progress + 0.028).clamp(0.0, 1.0),
        color: current.color,
        fontSize: current.fontSize,
      );
    }
    floatingPopups.removeWhere((p) => p.progress >= 1.0);
  }

  @override
  void dispose() {
    smartSpawner.removeListener(_onSpawnerUpdated);
    super.dispose();
  }
}

extension on LinesClearedEvent {
  int get totalClearedCountScore {
    final int lines = math.max(1, rows.length + cols.length);
    return lines * 100 * comboMultiplier + clearedPoints.length * 5;
  }
}

