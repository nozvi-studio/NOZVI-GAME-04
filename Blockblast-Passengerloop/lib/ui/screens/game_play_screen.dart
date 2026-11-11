import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/polyomino_shape.dart';
import '../../core/viewport_scaler.dart';
import '../../core/game_event_bus.dart';
import '../../core/pentatonic_audio_synth.dart';
import '../../core/haptics_manager.dart';
import '../../logic/commercial_game_controller.dart';
import '../../logic/win_streak_manager.dart';
import '../../logic/revive_controller.dart';
import '../../logic/bus_rush_race_service.dart';
import '../../logic/player_economy_service.dart';
import '../../logic/daily_quest_service.dart';
import '../widgets/revive_modal.dart';
import '../widgets/pause_modal.dart';
import '../widgets/victory_modal.dart';
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
  late final CommercialGameController _controller;

  // Tương tác Kéo Thả
  PolyominoShape? _draggingShape;
  int? _draggingSlotIndex;
  Offset? _currentDragPoint;
  PointInt? _hoverCell;
  bool _isValidSnap = false;
  PointInt? _hammerHoverCell;

  // Ticker 60fps: Thở phập phồng & chớp mắt tự nhiên ngay cả khi đang suy nghĩ
  late final AnimationController _idleTickerController;

  // Hoạt ảnh bay thú cưng Parabol & Popups (+150, COMBO x3!)
  late final AnimationController _animController;

  // Hiệu ứng phóng to đàn hồi ElasticOut khi refill khay Next
  late final AnimationController _trayRefillController;
  late final Animation<double> _trayRefillScale;

  // Bàn tay trắng chỉ đường FTUE
  late final AnimationController _handAnimController;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _controller = CommercialGameController();
    _controller.addListener(_onControllerUpdated);
    _controller.onTrayRefilled = _triggerTrayRefillAnimation;

    HapticsManager.instance.init();
    PlayerEconomyService.instance.init();
    WinStreakManager.instance.init();
    PetSanctuaryService.instance.init();
    BusRushRaceService.instance.init();
    DailyQuestService.instance.init();

    // Ticker 60fps chạy nền nhẹ nhàng không gây rebuild toàn Stack nhờ Listenable repaint ở CustomPainter
    _idleTickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(_onAnimTick);

    _trayRefillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0,
    );
    _trayRefillScale = CurvedAnimation(
      parent: _trayRefillController,
      curve: Curves.elasticOut,
    );

    _handAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        if (_controller.isTutorialActive && mounted) {
          setState(() {});
        }
      });

    _setupEventListeners();
    _startLevel(widget.initialLevel);

    if (PlayerEconomyService.instance.bgmEnabled) {
      PentatonicAudioSynth.instance.startBgm();
    }
  }

  void _onControllerUpdated() {
    if (_controller.isTutorialActive && !_handAnimController.isAnimating) {
      _handAnimController.repeat(reverse: true);
    } else if (!_controller.isTutorialActive && _handAnimController.isAnimating) {
      _handAnimController.stop();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _triggerTrayRefillAnimation() {
    if (mounted) {
      _trayRefillController.forward(from: 0.0);
    }
  }

  ViewportScaler _buildCurrentScaler() {
    final mediaQuery = MediaQuery.of(context);
    final safeSize = Size(
      mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right,
      mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
    );
    return ViewportScaler(
      screenSize: safeSize,
      padding: EdgeInsets.zero,
      dockCapacity: _controller.busStation.dockCapacity,
    );
  }

  void _setupEventListeners() {
    _subscriptions.add(GameEventBus.instance.on<BlockPlacedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playBlockDrop();
    }));

    _subscriptions.add(GameEventBus.instance.on<TrayRefilledEvent>().listen((event) {
      if (mounted) {
        _triggerTrayRefillAnimation();
        setState(() {});
      }
    }));

    _subscriptions.add(GameEventBus.instance.on<LinesClearedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playPetJump(comboIndex: event.comboMultiplier);
      if (mounted) {
        final scaler = _buildCurrentScaler();
        _controller.spawnClearPopups(event, scaler);
        if (!_animController.isAnimating) {
          _animController.forward(from: 0.0);
        }
      }
    }));

    _subscriptions.add(GameEventBus.instance.on<PassengersExtractedEvent>().listen((event) {
      if (mounted) {
        final scaler = _buildCurrentScaler();
        _controller.spawnFlyingPets(event.passengers, scaler);
        _animController.forward(from: 0.0);
      }
    }));

    _subscriptions.add(GameEventBus.instance.on<BusDispatchedEvent>().listen((event) {
      PentatonicAudioSynth.instance.playBusHorn();
      _controller.handleBusDispatched(event.bus);
    }));

    _subscriptions.add(GameEventBus.instance.on<GameWinEvent>().listen((event) async {
      PentatonicAudioSynth.instance.playWinFanfare();
      final coinsEarned = await _controller.handleMatchWin(event.stars);
      if (mounted) {
        _showVictoryModal(event.stars, event.score, coinsEarned);
      }
    }));

    _subscriptions.add(GameEventBus.instance.on<GameOverEvent>().listen((event) {
      if (mounted) {
        _handleGameOver(event.reason);
      }
    }));
  }

  void _startLevel(int level) {
    _controller.startLevel(level);
    if (_controller.isTutorialActive) {
      _handAnimController.repeat(reverse: true);
    } else {
      _handAnimController.stop();
      _triggerTrayRefillAnimation();
    }
    setState(() {});
  }

  void _openPauseModal() {
    setState(() {
      _controller.isPaused = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PauseModal(
        currentLevel: _controller.currentLevel,
        onResume: () {
          Navigator.pop(context);
          setState(() {
            _controller.isPaused = false;
          });
        },
        onRestart: () {
          Navigator.pop(context);
          _startLevel(_controller.currentLevel);
        },
        onBackToMap: () {
          Navigator.pop(context);
          widget.onBackToMenu();
        },
      ),
    );
  }

  void _showVictoryModal(int stars, int score, int coinsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VictoryModal(
        level: _controller.currentLevel,
        stars: stars,
        score: score,
        coinsEarned: coinsEarned,
        onNextLevel: () {
          Navigator.pop(context);
          final nextLevel = (_controller.currentLevel + 1).clamp(1, 200);
          _startLevel(nextLevel);
        },
        onBackToMap: () {
          Navigator.pop(context);
          widget.onBackToMenu();
        },
      ),
    );
  }

  void _handleGameOver(String reason) {
    if (!_controller.reviveController.hasUsedReviveInMatch) {
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
              _controller.reviveController.executeDockOverflowRevive(
                busStation: _controller.busStation,
              );
            } else {
              final activeColor = _controller.busStation.activeBus?.color ?? PetColor.red;
              _controller.reviveController.executeGridLockRevive(
                gridEngine: _controller.gridEngine,
                smartSpawner: _controller.smartSpawner,
                activeBusColor: activeColor,
              );
              _triggerTrayRefillAnimation();
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

  void _onAnimTick() {
    if (!mounted) return;
    setState(() {
      _controller.tickAnimations(_animController.value);
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _controller.removeListener(_onControllerUpdated);
    _controller.dispose();
    _idleTickerController.dispose();
    _animController.dispose();
    _trayRefillController.dispose();
    _handAnimController.dispose();
    PentatonicAudioSynth.instance.stopBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerEconomyService.instance,
      builder: (context, _) {
        final activeSkin = PlayerEconomyService.instance.activeSkin;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF88D45E),
                  Color(0xFF5BB344),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final safeSize = Size(constraints.maxWidth, constraints.maxHeight);
                  final scaler = ViewportScaler(
                    screenSize: safeSize,
                    padding: EdgeInsets.zero,
                    dockCapacity: _controller.busStation.dockCapacity,
                  );

                  return GestureDetector(
                    onPanStart: (details) => _handlePanStart(details.localPosition, scaler),
                    onPanUpdate: (details) => _handlePanUpdate(details.localPosition, scaler),
                    onPanEnd: (_) => _handlePanEnd(scaler),
                    onTapUp: (details) => _handleTap(details.localPosition, scaler),
                    child: Stack(
                      children: [
                        // 1. Nền công viên Gradient, Trạm xe buýt 2.5D, Ghế dài Holding Dock & Đường bay Parabol
                        CustomPaint(
                          size: safeSize,
                          painter: BusStationPainter(
                            scaler: scaler,
                            activeBus: _controller.busStation.activeBus,
                            nextBus: _controller.busStation.nextBus,
                            holdingDock: _controller.busStation.holdingDock,
                            score: _controller.actionQueue.currentScore,
                            currentLevel: _controller.currentLevel,
                            flyingPets: _controller.flyingPets,
                            skin: activeSkin,
                          ),
                        ),

                        // 2. Bàn cờ gỗ 8x8 2.5D + Kawaii25DRenderer (Ticker 60fps thở & chớp mắt) + Line Highlight Glow
                        CustomPaint(
                          size: safeSize,
                          painter: Board25DPainter(
                            scaler: scaler,
                            cells: _controller.gridEngine.cells,
                            draggingShape: _draggingShape,
                            ghostCell: _hoverCell,
                            isValidGhost: _isValidSnap,
                            linePreview: _controller.activeLinePreview,
                            isHammerActive: _controller.isHammerActive,
                            hammerHoverCell: _hammerHoverCell,
                            comboEffects: _controller.floatingPopups,
                            skin: activeSkin,
                            repaint: _idleTickerController,
                            getElapsedSec: () {
                              final elapsed = _idleTickerController.lastElapsedDuration;
                              if (elapsed != null) {
                                return elapsed.inMicroseconds / 1000000.0;
                              }
                              return _idleTickerController.value * 60.0;
                            },
                          ),
                        ),

                        // 3. Zone D: Búa Rèn Lửa, 3 ô Khay Next (Scale ElasticOut 0->1), La Bàn Gió
                        _buildZoneDControls(scaler, activeSkin),

                        // 4. Khối gạch đang bay theo ngón tay (với touchOffsetY = -70.0)
                        if (_draggingShape != null && _currentDragPoint != null)
                          Positioned(
                            left: _currentDragPoint!.dx - (_draggingShape!.width * scaler.cellSize) / 2,
                            top: _currentDragPoint!.dy + ViewportScaler.touchOffsetY - (_draggingShape!.height * scaler.cellSize) / 2,
                            child: IgnorePointer(
                              child: _buildDraggingShapeWidget(_draggingShape!, scaler.cellSize, activeSkin),
                            ),
                          ),

                        // 5. Lớp phủ Hướng dẫn FTUE 3 bước
                        if (_controller.isTutorialActive)
                          IgnorePointer(
                            child: CustomPaint(
                              size: safeSize,
                              painter: TutorialOverlayPainter(
                                scaler: scaler,
                                stepIndex: _controller.tutorialStep,
                                title: _controller.tutorialStep == 1
                                    ? 'Bước 1: Ghép Khối Cơ Bản'
                                    : (_controller.tutorialStep == 2
                                        ? 'Bước 2: Đón Corgi Lên Xe Buýt'
                                        : 'Bước 3: Cơ Chế Ghế Chờ'),
                                dialogue: _controller.tutorialStep == 1
                                    ? 'Kéo khối Corgi Đỏ 1x1 vào ô trống Hàng 4 để nổ hàng!'
                                    : (_controller.tutorialStep == 2
                                        ? 'Kéo khối Đỏ 1x2 vào Hàng 7 sáng đèn để tiễn Xe Buýt!'
                                        : 'Đặt Mèo Vàng vào Hàng 2 để Corgi lên xe & Mèo ngồi ghế chờ!'),
                                highlightRow: _controller.tutorialStep == 1
                                    ? 4
                                    : (_controller.tutorialStep == 2 ? 7 : 2),
                                targetRow: _controller.tutorialStep == 1
                                    ? 4
                                    : (_controller.tutorialStep == 2 ? 7 : 2),
                                targetCol: _controller.tutorialStep == 1
                                    ? 3
                                    : (_controller.tutorialStep == 2 ? 2 : 4),
                                startTraySlot: 0,
                                handProgress: _handAnimController.value,
                              ),
                            ),
                          ),

                        // Nút "Bỏ qua hướng dẫn (Skip FTUE)"
                        if (_controller.isTutorialActive)
                          Positioned(
                            top: 42,
                            right: 14,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD84D),
                                foregroundColor: const Color(0xFF3B2314),
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFF6D4226), width: 1.5),
                                ),
                              ),
                              icon: const Icon(Icons.fast_forward_rounded, size: 15),
                              label: const Text(
                                'Bỏ qua hướng dẫn (Skip FTUE)',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                              ),
                              onPressed: () {
                                _handAnimController.stop();
                                _controller.skipTutorial();
                              },
                            ),
                          ),

                        // Hai nút góc trên trái: Tạm dừng (Pause) và Hướng dẫn (?)
                        Positioned(
                          top: 5,
                          left: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopCircleButton(
                                icon: Icons.pause_rounded,
                                tooltip: 'Tạm dừng',
                                onTap: _openPauseModal,
                              ),
                              const SizedBox(width: 6),
                              _buildTopCircleButton(
                                icon: Icons.help_outline_rounded,
                                tooltip: 'Hướng dẫn (?)',
                                onTap: () {
                                  if (_controller.isTutorialActive) {
                                    _controller.skipTutorial();
                                  } else {
                                    _controller.openTutorialOverlay();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2B1D14).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9E633A), width: 1.4),
      ),
      child: IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 17),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildZoneDControls(ViewportScaler scaler, GameSkinTheme activeSkin) {
    return Positioned(
      left: scaler.zoneDRect.left,
      top: scaler.zoneDRect.top,
      width: scaler.zoneDRect.width,
      height: scaler.zoneDRect.height,
      child: Stack(
        children: [
          Positioned(
            left: scaler.hammerButtonRect.left,
            top: scaler.hammerButtonRect.top - scaler.zoneDRect.top,
            width: scaler.hammerButtonRect.width,
            height: scaler.hammerButtonRect.height,
            child: _buildSkillButton(
              icon: '🔨',
              charge: _controller.actionQueue.hammerCharge,
              maxCharge: _controller.actionQueue.hammerMaxCharge,
              isActive: _controller.isHammerActive,
              glowColor: const Color(0xFFFF6B5B),
              onTap: _toggleHammer,
            ),
          ),

          for (int i = 0; i < 3; i++)
            Positioned(
              left: scaler.traySlotRects[i].left,
              top: scaler.traySlotRects[i].top - scaler.zoneDRect.top,
              width: scaler.traySlotRects[i].width,
              height: scaler.traySlotRects[i].height,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A2E1B).withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9E633A).withValues(alpha: 0.65),
                    width: 1.5,
                  ),
                ),
                child: (_controller.smartSpawner.traySlots[i] != null && _draggingSlotIndex != i)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ScaleTransition(
                            scale: _trayRefillScale,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _buildTrayShapeWidget(
                                _controller.smartSpawner.traySlots[i]!,
                                scaler.cellSize,
                                activeSkin,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),

          Positioned(
            left: scaler.compassButtonRect.left,
            top: scaler.compassButtonRect.top - scaler.zoneDRect.top,
            width: scaler.compassButtonRect.width,
            height: scaler.compassButtonRect.height,
            child: _buildSkillButton(
              icon: '🧭',
              charge: _controller.actionQueue.compassCharge,
              maxCharge: _controller.actionQueue.compassMaxCharge,
              isActive: false,
              glowColor: const Color(0xFF4FC3F7),
              onTap: () => _controller.activateCompass(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButton({
    required String icon,
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? [glowColor, const Color(0xFF6D4226)]
                : [const Color(0xFF9E633A), const Color(0xFF6D4226)],
          ),
          border: Border.all(
            color: isReady ? glowColor : const Color(0xFF3B2314),
            width: isReady ? 2.8 : 2.0,
          ),
          boxShadow: [
            const BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3)),
            if (isReady)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.65),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 19)),
            Text(
              isReady ? 'SẴN SÀNG' : '$charge/$maxCharge',
              style: TextStyle(
                color: isReady ? const Color(0xFFFFD84D) : Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrayShapeWidget(PolyominoShape shape, double boardCellSize, GameSkinTheme skin) {
    const double trayScale = 0.62;
    return CustomPaint(
      size: Size(
        shape.width * boardCellSize * trayScale,
        shape.height * boardCellSize * trayScale,
      ),
      painter: PolyominoShape25DPainter(
        shape: shape,
        cellSize: boardCellSize,
        skin: skin,
      ),
    );
  }

  Widget _buildDraggingShapeWidget(PolyominoShape shape, double tileSize, GameSkinTheme skin) {
    return CustomPaint(
      size: Size(shape.width * tileSize, shape.height * tileSize),
      painter: PolyominoShape25DPainter(
        shape: shape,
        cellSize: tileSize,
        skin: skin,
      ),
    );
  }

  // --- XỬ LÝ CỬ CHỈ CHẠM & KÉO THẢ ---

  void _handlePanStart(Offset point, ViewportScaler scaler) {
    if (_controller.isPaused || _controller.actionQueue.isLocked || _controller.isHammerActive) return;

    for (int i = 0; i < 3; i++) {
      if (scaler.traySlotRects[i].contains(point)) {
        final shape = _controller.smartSpawner.traySlots[i];
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
        final preview = _controller.previewLinesIfPlaced(_draggingShape!, cell.r, cell.c);
        _isValidSnap = preview.isValid;
      } else {
        _controller.clearLinePreview();
        _isValidSnap = false;
      }
    });
  }

  void _handlePanEnd(ViewportScaler scaler) async {
    HapticsManager.instance.resetHover();
    _controller.clearLinePreview();
    if (_draggingShape == null || _draggingSlotIndex == null) return;

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
      await _controller.placeBlockAndProcess(
        shape: shape,
        slotIndex: slot,
        targetRow: target.r,
        targetCol: target.c,
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _handleTap(Offset point, ViewportScaler scaler) {
    if (_controller.isPaused) return;
    if (_controller.isHammerActive) {
      final cell = scaler.getGridCellFromTouch(point - const Offset(0, ViewportScaler.touchOffsetY));
      if (cell != null) {
        _controller.smashHammerAt(cell.r, cell.c);
      }
    }
  }

  void _toggleHammer() {
    if (_controller.actionQueue.hammerCharge >= _controller.actionQueue.hammerMaxCharge) {
      setState(() {
        _controller.isHammerActive = !_controller.isHammerActive;
      });
    }
  }

  void _showGameOverDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFA82419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('😢 HẾT LƯỢT!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          reason == 'DOCK_OVERFLOW' ? 'Ghế chờ Holding Dock đã đầy chỗ!' : 'Không còn nước đi hợp lệ nào trên bàn cờ!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
              _startLevel(_controller.currentLevel);
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
