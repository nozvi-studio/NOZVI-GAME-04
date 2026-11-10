import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/grid_cell_data.dart';
import '../../models/polyomino_shape.dart';
import '../../models/bus_data.dart';
import '../../core/viewport_scaler.dart';
import '../../core/game_event_bus.dart';
import '../../core/action_queue.dart';
import '../../core/pentatonic_audio_synth.dart';
import '../../core/haptics_manager.dart';
import '../../logic/grid_engine.dart';
import '../../logic/bus_station_manager.dart';
import '../../logic/smart_spawner.dart';
import '../../logic/level_generator.dart';
import '../../logic/win_streak_manager.dart';
import '../../logic/revive_controller.dart';
import '../../logic/bus_rush_race_service.dart';
import '../widgets/revive_modal.dart';
import '../screens/pet_sanctuary_screen.dart';
import '../painters/board_25d_painter.dart';
import '../painters/bus_station_painter.dart';
import '../painters/tutorial_overlay.dart';

class GamePlayScreen extends StatefulWidget {
  final int initialLevel;
  final VoidCallback onBackToMenu;

  const GamePlayScreen({
    super.key,
    required this.initialLevel,
    required this.onBackToMenu,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with TickerProviderStateMixin {
  late final GridEngine _gridEngine;
  late final BusStationManager _busStation;
  late final SmartSpawner _smartSpawner;
  late final ActionQueue _actionQueue;
  late final ReviveController _reviveController;

  late int _currentLevel;
  late GameLevelConfig _levelConfig;

  // Tương tác Kéo Thả
  PolyominoShape? _draggingShape;
  int? _draggingSlotIndex;
  Offset? _currentDragPoint;
  PointInt? _hoverCell;
  bool _isValidSnap = false;

  // Kỹ năng Búa Rèn Lửa
  bool _isHammerActive = false;
  PointInt? _hammerHoverCell;

  // Hoạt ảnh
  late final AnimationController _animController;
  final List<FlyingPetArc> _flyingPets = [];
  final List<ComboEffectData> _comboEffects = [];

  // Hướng dẫn FTUE
  bool _isTutorial = false;
  int _tutorialStep = 1;
  late final AnimationController _handAnimController;

  // Stream Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    _gridEngine = GridEngine();
    _busStation = BusStationManager();
    _smartSpawner = SmartSpawner();
    _actionQueue = ActionQueue(
      gridEngine: _gridEngine,
      busStation: _busStation,
      smartSpawner: _smartSpawner,
    );
    _reviveController = ReviveController();

    HapticsManager.instance.init();
    WinStreakManager.instance.init();
    PetSanctuaryService.instance.init();
    BusRushRaceService.instance.init();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(_onAnimTick);

    _handAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _setupEventListeners();
    _startLevel(_currentLevel);
  }

  void _setupEventListeners() {
    _subscriptions.add(GameEventBus.instance.on<BlockPlacedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playBlockDrop();
    }));

    _subscriptions.add(GameEventBus.instance.on<LinesClearedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playPetJump(comboIndex: event.comboMultiplier);
      if (mounted) {
        setState(() {
          _comboEffects.add(ComboEffectData(
            text: 'Combo x${event.comboMultiplier}!',
            position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height * 0.45),
            progress: 0.0,
          ));
        });
      }
    }));

    _subscriptions.add(GameEventBus.instance.on<PassengersExtractedEvent>().listen((event) {
      _triggerPassengerFlight(event.passengers);
    }));

    _subscriptions.add(GameEventBus.instance.on<BusDispatchedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playBusHorn();
      PetSanctuaryService.instance.recordBusDeparted(event.bus);
      BusRushRaceService.instance.recordPlayerBuses(1);
    }));

    _subscriptions.add(GameEventBus.instance.on<GameWinEvent>().listen((event) {
      PentatonicAudioSynth.instance.playWinFanfare();
      WinStreakManager.instance.recordWin();
      _showWinDialog(event.stars, event.score);
    }));

    _subscriptions.add(GameEventBus.instance.on<GameOverEvent>().listen((event) {
      _handleGameOver(event.reason);
    }));
  }

  void _handleGameOver(String reason) {
    if (!_reviveController.hasUsedReviveInMatch) {
      final type = reason == 'DOCK_OVERFLOW'
          ? ReviveType.dockOverflow
          : ReviveType.gridLock;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReviveModal(
          type: type,
          onRevive: () async {
            Navigator.pop(context);
            if (type == ReviveType.dockOverflow) {
              _reviveController.executeDockOverflowRevive(
                busStation: _busStation,
              );
            } else {
              final activeColor = _busStation.activeBus?.color ?? PetColor.red;
              _reviveController.executeGridLockRevive(
                gridEngine: _gridEngine,
                smartSpawner: _smartSpawner,
                activeBusColor: activeColor,
              );
            }
            setState(() {});
          },
          onGiveUp: () async {
            Navigator.pop(context);
            await WinStreakManager.instance.resetStreak();
            if (mounted) {
              _showGameOverDialog(reason);
            }
          },
        ),
      );
    } else {
      WinStreakManager.instance.resetStreak();
      _showGameOverDialog(reason);
    }
  }

  void _startLevel(int level) {
    _currentLevel = level;
    _isTutorial = (level == 0);
    _levelConfig = LevelGenerator.getLevel(level);
    _reviveController.reset();

    _actionQueue.resetScore(level);
    _actionQueue.setInitialCharges(
      hammer: WinStreakManager.instance.startingHammerCharges,
      compass: WinStreakManager.instance.startingCompassCharges,
    );

    // Cập nhật sức chứa Holding Dock theo Super Bus Streak
    _busStation.setDockCapacity(WinStreakManager.instance.dockCapacity);

    // Nạp danh sách xe buýt, kích hoạt Rainbow Express nếu đạt Streak Tier 3
    final buses = _levelConfig.buses.map((b) => b.clone()).toList();
    if (buses.isNotEmpty && WinStreakManager.instance.firstBusIsRainbow) {
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
    _busStation.initializeBuses(buses);
    _gridEngine.loadInitialLayout(_levelConfig.initialGrid);

    // Áp dụng khóa ghế chờ nếu màn chơi yêu cầu
    for (final slotIdx in _levelConfig.lockedDockSlots) {
      if (slotIdx >= 0 && slotIdx < _busStation.holdingDock.length) {
        _busStation.holdingDock[slotIdx].isLocked = true;
      }
    }

    // Nạp đợt gạch đầu tiên
    _smartSpawner.generateNewBatch(
      availableColors: _levelConfig.availableColors,
      activeBus: _busStation.activeBus,
      nextBus: _busStation.nextBus,
      emptyBoardCells: _gridEngine.emptyCellCount,
    );

    if (_isTutorial) {
      _tutorialStep = 1;
      _setupTutorialStep(1);
    }

    setState(() {});
  }

  void _setupTutorialStep(int step) {
    _tutorialStep = step;
    if (step == 1) {
      // Hàng 4 có 7 ô đầy, ô 3 trống
      final cells = <GridCellData>[];
      for (int c = 0; c < 8; c++) {
        if (c != 3) {
          cells.add(GridCellData(row: 4, col: c, petColor: PetColor.red));
        }
      }
      _gridEngine.loadInitialLayout(cells);
      _smartSpawner.nextShapes[0] = PolyominoShape(
        id: 'tut_dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.red)],
        width: 1,
        height: 1,
      );
      _smartSpawner.nextShapes[1] = null;
      _smartSpawner.nextShapes[2] = null;
    } else if (step == 2) {
      // Hàng 7 có 6 ô đầy, ô 2, 3 trống
      final cells = <GridCellData>[];
      for (int c = 0; c < 8; c++) {
        if (c != 2 && c != 3) {
          cells.add(GridCellData(row: 7, col: c, petColor: PetColor.red));
        }
      }
      _gridEngine.loadInitialLayout(cells);
      _busStation.activeBus?.currentPassengers = 1; // 1/3
      _smartSpawner.nextShapes[0] = PolyominoShape(
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
      // Hàng 2 có Mèo vàng
      final cells = <GridCellData>[];
      for (int c = 0; c < 8; c++) {
        if (c != 4) {
          cells.add(GridCellData(row: 2, col: c, petColor: PetColor.yellow));
        }
      }
      _gridEngine.loadInitialLayout(cells);
      _smartSpawner.nextShapes[0] = PolyominoShape(
        id: 'tut_cat_dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.yellow)],
        width: 1,
        height: 1,
      );
    }
  }

  void _triggerPassengerFlight(List<PassengerExtractionItem> passengers) {
    final mediaQuery = MediaQuery.of(context);
    final scaler = ViewportScaler(
      screenSize: mediaQuery.size,
      padding: mediaQuery.padding,
      dockCapacity: _busStation.dockCapacity,
    );

    for (final p in passengers) {
      final start = scaler.getCellCenter(p.fromRow, p.fromCol);
      final Offset end;
      if (p.destination == PassengerDestination.bus) {
        end = scaler.activeBusDoorCenter;
      } else {
        end = scaler.getDockSlotCenter(p.dockSlotIndex ?? 0);
      }

      _flyingPets.add(FlyingPetArc(
        id: p.id,
        color: p.color,
        start: start,
        end: end,
        progress: 0.0,
      ));
    }

    _animController.forward(from: 0.0);
  }

  void _onAnimTick() {
    final progress = _animController.value;
    setState(() {
      for (int i = 0; i < _flyingPets.length; i++) {
        _flyingPets[i] = FlyingPetArc(
          id: _flyingPets[i].id,
          color: _flyingPets[i].color,
          start: _flyingPets[i].start,
          end: _flyingPets[i].end,
          progress: progress,
        );
      }
      if (progress >= 1.0) {
        _flyingPets.clear();
      }

      // Diễn hoạt chữ Combo x4!
      for (int i = 0; i < _comboEffects.length; i++) {
        final current = _comboEffects[i];
        _comboEffects[i] = ComboEffectData(
          text: current.text,
          position: current.position,
          progress: (current.progress + 0.03).clamp(0.0, 1.0),
        );
      }
      _comboEffects.removeWhere((c) => c.progress >= 1.0);
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _animController.dispose();
    _handAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final scaler = ViewportScaler(
      screenSize: mediaQuery.size,
      padding: mediaQuery.padding,
      dockCapacity: _busStation.dockCapacity,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: SafeArea(
        child: GestureDetector(
          onPanStart: (details) => _handlePanStart(details.localPosition, scaler),
          onPanUpdate: (details) => _handlePanUpdate(details.localPosition, scaler),
          onPanEnd: (_) => _handlePanEnd(scaler),
          onTapUp: (details) => _handleTap(details.localPosition, scaler),
          child: Stack(
            children: [
              // 1. Vẽ Trạm xe buýt, Ghế chờ Holding Dock & Đường bay thú cưng
              CustomPaint(
                size: mediaQuery.size,
                painter: BusStationPainter(
                  scaler: scaler,
                  activeBus: _busStation.activeBus,
                  nextBus: _busStation.nextBus,
                  holdingDock: _busStation.holdingDock,
                  score: _actionQueue.currentScore,
                  currentLevel: _currentLevel,
                  flyingPets: _flyingPets,
                ),
              ),

              // 2. Vẽ Bàn cờ 8x8 2.5D, Khối gạch, Ghost Preview & Hiệu ứng
              CustomPaint(
                size: mediaQuery.size,
                painter: Board25DPainter(
                  scaler: scaler,
                  cells: _gridEngine.cells,
                  draggingShape: _draggingShape,
                  ghostCell: _hoverCell,
                  isValidGhost: _isValidSnap,
                  isHammerActive: _isHammerActive,
                  hammerHoverCell: _hammerHoverCell,
                  comboEffects: _comboEffects,
                ),
              ),

              // 3. Zone D: 2 Nút Cổ vật & Khay 3 khối gạch
              _buildZoneDControls(scaler),

              // 4. Khối gạch đang bay theo ngón tay (với touchOffsetY = -70.0)
              if (_draggingShape != null && _currentDragPoint != null)
                Positioned(
                  left: _currentDragPoint!.dx - (_draggingShape!.width * scaler.cellSize) / 2,
                  top: _currentDragPoint!.dy + ViewportScaler.touchOffsetY - (_draggingShape!.height * scaler.cellSize) / 2,
                  child: IgnorePointer(
                    child: _buildDraggingShapeWidget(_draggingShape!, scaler.cellSize),
                  ),
                ),

              // 5. Lớp phủ Hướng dẫn FTUE
              if (_isTutorial)
                CustomPaint(
                  size: mediaQuery.size,
                  painter: TutorialOverlayPainter(
                    scaler: scaler,
                    stepIndex: _tutorialStep,
                    title: _tutorialStep == 1
                        ? 'Bước 1: Ghép Khối Cơ Bản'
                        : (_tutorialStep == 2
                            ? 'Bước 2: Cứu Thú Lên Xe Buýt'
                            : 'Bước 3: Cơ Chế Ghế Chờ'),
                    dialogue: _tutorialStep == 1
                        ? 'Kéo khối Corgi Đỏ 1x1 vào ô trống Hàng 4 để tạo hàng thẳng và nổ điểm!'
                        : (_tutorialStep == 2
                            ? 'Kéo khối Đỏ 1x2 vào Hàng 7 đang sáng đèn để đón 2 chú Corgi lên xe!'
                            : 'Phá hàng chứa Mèo Vàng khi xe ở trạm là Xe Đỏ để Mèo ngồi đợi ở ghế!'),
                    highlightRow: _tutorialStep == 1 ? 4 : (_tutorialStep == 2 ? 7 : 2),
                    targetRow: _tutorialStep == 1 ? 4 : (_tutorialStep == 2 ? 7 : 2),
                    targetCol: _tutorialStep == 1 ? 3 : (_tutorialStep == 2 ? 2 : 4),
                    startTraySlot: 0,
                    handProgress: _handAnimController.value,
                  ),
                ),

              // Nút Trở về Menu ở góc trên bên trái
              Positioned(
                top: 8,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: widget.onBackToMenu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng Zone D: Nút Búa Rèn Lửa, Khay gạch Next, Nút La Bàn Gió
  Widget _buildZoneDControls(ViewportScaler scaler) {
    return Positioned(
      left: scaler.zoneDRect.left,
      top: scaler.zoneDRect.top,
      width: scaler.zoneDRect.width,
      height: scaler.zoneDRect.height,
      child: Stack(
        children: [
          // Nút Trái: BÚA RÈN LỬA
          Positioned(
            left: scaler.hammerButtonRect.left,
            top: scaler.hammerButtonRect.top - scaler.zoneDRect.top,
            width: scaler.hammerButtonRect.width,
            height: scaler.hammerButtonRect.height,
            child: _buildSkillButton(
              icon: '🔨',
              label: 'BÚA',
              charge: _actionQueue.hammerCharge,
              maxCharge: _actionQueue.hammerMaxCharge,
              isActive: _isHammerActive,
              glowColor: const Color(0xFFFF3D00),
              onTap: _toggleHammer,
            ),
          ),

          // 3 Khay gạch ở giữa
          for (int i = 0; i < 3; i++)
            if (_smartSpawner.nextShapes[i] != null && _draggingSlotIndex != i)
              Positioned(
                left: scaler.traySlotRects[i].left,
                top: scaler.traySlotRects[i].top - scaler.zoneDRect.top,
                width: scaler.traySlotRects[i].width,
                height: scaler.traySlotRects[i].height,
                child: Center(
                  child: _buildTrayShapeWidget(_smartSpawner.nextShapes[i]!, scaler.cellSize * 0.65),
                ),
              ),

          // Nút Phải: LA BÀN GIÓ
          Positioned(
            left: scaler.compassButtonRect.left,
            top: scaler.compassButtonRect.top - scaler.zoneDRect.top,
            width: scaler.compassButtonRect.width,
            height: scaler.compassButtonRect.height,
            child: _buildSkillButton(
              icon: '🧭',
              label: 'LA BÀN',
              charge: _actionQueue.compassCharge,
              maxCharge: _actionQueue.compassMaxCharge,
              isActive: false,
              glowColor: const Color(0xFF00E5FF),
              onTap: _useCompass,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButton({
    required String icon,
    required String label,
    required int charge,
    required int maxCharge,
    required bool isActive,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    final bool isReady = charge >= maxCharge;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? glowColor : const Color(0xFF2E2E2E),
          border: Border.all(
            color: isReady ? glowColor : Colors.white24,
            width: isReady ? 2.5 : 1.2,
          ),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            Text(
              isReady ? 'SẴN SÀNG' : '$charge/$maxCharge',
              style: TextStyle(
                color: isReady ? Colors.white : Colors.white60,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrayShapeWidget(PolyominoShape shape, double tileSize) {
    return SizedBox(
      width: shape.width * tileSize,
      height: shape.height * tileSize,
      child: Stack(
        children: shape.tiles.map((tile) {
          return Positioned(
            left: tile.c * tileSize,
            top: tile.r * tileSize,
            width: tileSize - 2,
            height: tileSize - 2,
            child: Container(
              decoration: BoxDecoration(
                color: tile.petColor.primaryColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tile.petColor.darkColor, width: 1.5),
              ),
              child: Center(
                child: Text(tile.petColor.emoji, style: TextStyle(fontSize: tileSize * 0.5)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDraggingShapeWidget(PolyominoShape shape, double tileSize) {
    return SizedBox(
      width: shape.width * tileSize,
      height: shape.height * tileSize,
      child: Stack(
        children: shape.tiles.map((tile) {
          return Positioned(
            left: tile.c * tileSize,
            top: tile.r * tileSize,
            width: tileSize - 2,
            height: tileSize - 2,
            child: Container(
              decoration: BoxDecoration(
                color: tile.petColor.primaryColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(tile.petColor.emoji, style: TextStyle(fontSize: tileSize * 0.55)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- XỬ LÝ CỬ CHỈ CHẠM & KÉO THẢ ---

  void _handlePanStart(Offset point, ViewportScaler scaler) {
    if (_actionQueue.isLocked || _isHammerActive) return;

    for (int i = 0; i < 3; i++) {
      if (scaler.traySlotRects[i].contains(point)) {
        final shape = _smartSpawner.takeShape(i);
        if (shape != null) {
          setState(() {
            _draggingShape = shape;
            _draggingSlotIndex = i;
            _currentDragPoint = point;
          });
          break;
        }
      }
    }
  }

  void _handlePanUpdate(Offset point, ViewportScaler scaler) {
    if (_draggingShape == null) return;

    setState(() {
      _currentDragPoint = point;
      final cell = scaler.getGridCellFromTouch(point);
      _hoverCell = cell;
      if (cell != null) {
        HapticsManager.instance.onHoverCell(cell.r, cell.c);
        _isValidSnap = _gridEngine.canPlacePolyomino(_draggingShape!, cell.r, cell.c);
      } else {
        _isValidSnap = false;
      }
    });
  }

  void _handlePanEnd(ViewportScaler scaler) async {
    HapticsManager.instance.resetHover();
    if (_draggingShape == null) return;

    final shape = _draggingShape!;
    final slot = _draggingSlotIndex!;
    final target = _hoverCell;
    final canPlace = _isValidSnap && target != null;

    setState(() {
      _draggingShape = null;
      _draggingSlotIndex = null;
      _currentDragPoint = null;
      _hoverCell = null;
      _isValidSnap = false;
    });

    if (canPlace) {
      await _actionQueue.executeBlockDrop(
        shape: shape,
        targetRow: target.r,
        targetCol: target.c,
        availableColors: _levelConfig.availableColors,
      );

      if (_isTutorial) {
        if (_tutorialStep == 1) {
          _setupTutorialStep(2);
        } else if (_tutorialStep == 2) {
          _setupTutorialStep(3);
        } else if (_tutorialStep == 3) {
          _showWinDialog(3, _actionQueue.currentScore);
        }
      }
    } else {
      // Trả lại khay nếu kéo ra ngoài
      _smartSpawner.returnShape(slot, shape);
    }
  }

  void _handleTap(Offset point, ViewportScaler scaler) {
    if (_isHammerActive) {
      final cell = scaler.getGridCellFromTouch(point - const Offset(0, ViewportScaler.touchOffsetY));
      if (cell != null) {
        _executeHammerAt(cell.r, cell.c);
      }
    }
  }

  void _toggleHammer() {
    if (_actionQueue.hammerCharge >= _actionQueue.hammerMaxCharge) {
      setState(() {
        _isHammerActive = !_isHammerActive;
      });
    }
  }

  void _useCompass() {
    if (_actionQueue.compassCharge >= _actionQueue.compassMaxCharge) {
      final rotated = _actionQueue.executeWindCompass();
      if (rotated) {
        PentatonicAudioSynth.instance.playWindCompass();
        setState(() {});
      }
    }
  }

  void _executeHammerAt(int r, int c) async {
    setState(() {
      _isHammerActive = false;
    });
    PentatonicAudioSynth.instance.playHammerSmash();
    await _actionQueue.executeHammerSmash(
      centerRow: r,
      centerCol: c,
      availableColors: _levelConfig.availableColors,
    );
  }

  void _showWinDialog(int stars, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 CHIẾN THẮNG!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(Icons.star, color: i < stars ? const Color(0xFFFFD600) : Colors.white24, size: 36)),
            ),
            const SizedBox(height: 12),
            Text('Điểm số: $score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD54F), foregroundColor: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
              _startLevel(_currentLevel + 1);
            },
            child: const Text('MÀN TIẾP THEO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBackToMenu();
            },
            child: const Text('MENU CHÍNH', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFC62828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('😢 HẾT LƯỢT!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          reason == 'DOCK_OVERFLOW' ? 'Ghế chờ Holding Dock đã đầy 5 chỗ!' : 'Không còn nước đi hợp lệ nào trên bàn cờ!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
              _startLevel(_currentLevel);
            },
            child: const Text('CHƠI LẠI'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onBackToMenu();
            },
            child: const Text('MENU CHÍNH', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
