import 'dart:async';
import '../models/enums.dart';
import '../models/polyomino_shape.dart';
import '../models/bus_data.dart';

abstract class GameEvent {}

class BlockPlacedEvent extends GameEvent {
  final PolyominoShape shape;
  final int row;
  final int col;
  BlockPlacedEvent({required this.shape, required this.row, required this.col});
}

class LinesClearedEvent extends GameEvent {
  final List<int> rows;
  final List<int> cols;
  final int comboMultiplier;
  final List<PointInt> clearedPoints;
  LinesClearedEvent({
    required this.rows,
    required this.cols,
    required this.comboMultiplier,
    required this.clearedPoints,
  });
}

class PassengersExtractedEvent extends GameEvent {
  final List<PassengerExtractionItem> passengers;
  PassengersExtractedEvent({required this.passengers});
}

class PassengerBoardBusEvent extends GameEvent {
  final PassengerExtractionItem passenger;
  final BusData bus;
  PassengerBoardBusEvent({required this.passenger, required this.bus});
}

class PassengerEnterDockEvent extends GameEvent {
  final PassengerExtractionItem passenger;
  final int slotIndex;
  PassengerEnterDockEvent({required this.passenger, required this.slotIndex});
}

class BusDispatchedEvent extends GameEvent {
  final BusData bus;
  BusDispatchedEvent({required this.bus});
}

class NextBusArrivedEvent extends GameEvent {
  final BusData bus;
  NextBusArrivedEvent({required this.bus});
}

class DockPetBoardedEvent extends GameEvent {
  final PetColor petColor;
  final int slotIndex;
  final BusData bus;
  DockPetBoardedEvent({
    required this.petColor,
    required this.slotIndex,
    required this.bus,
  });
}

class HazardUpdatedEvent extends GameEvent {
  final HazardType hazard;
  final int row;
  final int col;
  final dynamic details;
  HazardUpdatedEvent({
    required this.hazard,
    required this.row,
    required this.col,
    this.details,
  });
}

class BombExplodedEvent extends GameEvent {
  final int centerRow;
  final int centerCol;
  final List<PointInt> affected;
  BombExplodedEvent({
    required this.centerRow,
    required this.centerCol,
    required this.affected,
  });
}

class VineSpreadEvent extends GameEvent {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  VineSpreadEvent({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });
}

class RelicChargedEvent extends GameEvent {
  final RelicType relic;
  final int current;
  final int max;
  final bool isReady;
  RelicChargedEvent({
    required this.relic,
    required this.current,
    required this.max,
    required this.isReady,
  });
}

class RelicUsedEvent extends GameEvent {
  final RelicType relic;
  RelicUsedEvent({required this.relic});
}

class ScoreChangedEvent extends GameEvent {
  final int score;
  final int delta;
  final int combo;
  ScoreChangedEvent({
    required this.score,
    required this.delta,
    required this.combo,
  });
}

class InputLockEvent extends GameEvent {
  final bool locked;
  final String? reason;
  InputLockEvent({required this.locked, this.reason});
}

class GameWinEvent extends GameEvent {
  final int level;
  final int score;
  final int stars;
  GameWinEvent({required this.level, required this.score, required this.stars});
}

class GameOverEvent extends GameEvent {
  final String reason;
  final int level;
  final int score;
  GameOverEvent({required this.reason, required this.level, required this.score});
}

class TutorialStepEvent extends GameEvent {
  final int stepIndex;
  final String title;
  final String dialogue;
  final int? targetRow;
  final int? targetCol;
  TutorialStepEvent({
    required this.stepIndex,
    required this.title,
    required this.dialogue,
    this.targetRow,
    this.targetCol,
  });
}

/// Central Event Bus for decoupled communication between Logic, UI and Audio
class GameEventBus {
  static final GameEventBus _instance = GameEventBus._internal();
  static GameEventBus get instance => _instance;

  final StreamController<GameEvent> _controller = StreamController<GameEvent>.broadcast();

  GameEventBus._internal();

  Stream<GameEvent> get stream => _controller.stream;

  Stream<T> on<T extends GameEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void fire(GameEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

