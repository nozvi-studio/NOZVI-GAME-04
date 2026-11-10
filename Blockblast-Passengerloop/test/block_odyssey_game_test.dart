import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_odyssey_pet_express/models/enums.dart';
import 'package:block_odyssey_pet_express/models/polyomino_shape.dart';
import 'package:block_odyssey_pet_express/models/bus_data.dart';
import 'package:block_odyssey_pet_express/logic/grid_engine.dart';
import 'package:block_odyssey_pet_express/logic/bus_station_manager.dart';
import 'package:block_odyssey_pet_express/logic/smart_spawner.dart';
import 'package:block_odyssey_pet_express/logic/level_generator.dart';
import 'package:block_odyssey_pet_express/logic/revive_controller.dart';
import 'package:block_odyssey_pet_express/logic/win_streak_manager.dart';
import 'package:block_odyssey_pet_express/logic/bus_rush_race_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Polyomino Shape & Rotation Tests', () {
    test('rotateClockwise rotates (r, c) by 90 degrees and normalizes', () {
      // Line 1x2 Horizontal: (0, 0), (0, 1)
      final shape = PolyominoShape(
        id: 'test_line',
        name: 'Line2_H',
        tiles: [
          const ShapeTile(r: 0, c: 0, petColor: PetColor.red),
          const ShapeTile(r: 0, c: 1, petColor: PetColor.red),
        ],
        width: 2,
        height: 1,
      );

      final rotated = shape.rotateClockwise();
      // Should become Vertical: width 1, height 2
      expect(rotated.width, equals(1));
      expect(rotated.height, equals(2));
      expect(rotated.rotation, equals(90));
      expect(rotated.tiles.any((t) => t.r == 0 && t.c == 0), isTrue);
      expect(rotated.tiles.any((t) => t.r == 1 && t.c == 0), isTrue);
    });
  });

  group('GridEngine Mechanics & Hazards Tests', () {
    test('Place polyomino and collision detection', () {
      final engine = GridEngine();
      final shape = PolyominoShape(
        id: 'dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.yellow)],
        width: 1,
        height: 1,
      );

      expect(engine.canPlacePolyomino(shape, 0, 0), isTrue);
      expect(engine.placePolyomino(shape, 0, 0), isTrue);

      // Cannot place again at same occupied cell
      expect(engine.canPlacePolyomino(shape, 0, 0), isFalse);

      // Cannot place outside boundary
      expect(engine.canPlacePolyomino(shape, 8, 8), isFalse);
    });

    test('Simultaneous row and column line clear with Combo multiplier', () {
      final engine = GridEngine();

      // Fill entire row 0 except col 0
      for (int c = 1; c < 8; c++) {
        engine.cells[0][c].petColor = PetColor.red;
      }
      // Fill entire col 0 except row 0
      for (int r = 1; r < 8; r++) {
        engine.cells[r][0].petColor = PetColor.blue;
      }

      // Drop 1x1 block at (0, 0) -> fills BOTH row 0 and col 0 simultaneously!
      final dot = PolyominoShape(
        id: 'cross_dot',
        name: 'Dot1x1',
        tiles: [const ShapeTile(r: 0, c: 0, petColor: PetColor.green)],
        width: 1,
        height: 1,
      );
      engine.placePolyomino(dot, 0, 0);

      final result = engine.evaluateLines();
      expect(result.fullRows, contains(0));
      expect(result.fullCols, contains(0));
      expect(result.comboMultiplier, equals(2)); // Double clear -> Combo x2!

      final freed = engine.executeLineClear(result.clearedPoints);
      expect(freed.isNotEmpty, isTrue);
      expect(engine.cells[0][0].petColor, isNull);
    });

    test('Ice hazard requires 2 line clears to free pet', () {
      final engine = GridEngine();
      engine.cells[3][3].petColor = PetColor.blue;
      engine.cells[3][3].hazard = HazardType.ice;
      engine.cells[3][3].iceLayer = 2; // Solid ice

      // 1st clear
      final freed1 = engine.executeLineClear([const PointInt(3, 3)]);
      expect(freed1.isEmpty, isTrue); // Pet still trapped inside ice!
      expect(engine.cells[3][3].iceLayer, equals(1)); // Cracked ice

      // 2nd clear
      final freed2 = engine.executeLineClear([const PointInt(3, 3)]);
      expect(freed2.length, equals(1)); // Pet freed!
      expect(freed2.first.color, equals(PetColor.blue));
      expect(engine.cells[3][3].iceLayer, equals(0));
      expect(engine.cells[3][3].hazard, isNull);
    });

    test('Bomb ticks down and explodes 3x3 on 0', () {
      final engine = GridEngine();
      engine.cells[4][4].hazard = HazardType.bomb;
      engine.cells[4][4].bombTurns = 1;

      // Update hazards -> countdown to 0 -> explodes
      engine.updateHazards();
      expect(engine.cells[4][4].isLocked, isTrue);
      expect(engine.cells[3][3].isLocked, isTrue); // 3x3 locked
      expect(engine.cells[5][5].isLocked, isTrue);
    });

    test('Hammer relic destroys 3x3 area', () {
      final engine = GridEngine();
      engine.cells[1][1].petColor = PetColor.red;
      engine.cells[1][2].hazard = HazardType.stone;

      final freed = engine.destroy3x3Area(1, 1);
      expect(freed.any((p) => p.color == PetColor.red), isTrue);
      expect(engine.cells[1][2].hazard, isNull); // Stone destroyed
    });
  });

  group('BusStationManager & Passenger Priority Algorithm Tests', () {
    test('extractAndSortPassengers prioritizes activeBus matching color first', () {
      final station = BusStationManager();
      station.initializeBuses([
        BusData(id: 'red_bus', color: PetColor.red, name: 'Corgi Bus', capacity: 2),
        BusData(id: 'yellow_bus', color: PetColor.yellow, name: 'Cat Bus', capacity: 2),
      ]);

      // Freed pets: 1 Yellow Cat and 1 Red Corgi
      final freed = [
        const FreedPetInfo(row: 0, col: 0, color: PetColor.yellow),
        const FreedPetInfo(row: 0, col: 1, color: PetColor.red),
      ];

      final result = station.extractAndSortPassengers(freed);

      // Red Corgi should board active red bus first!
      expect(station.activeBus!.currentPassengers, equals(1));
      expect(station.activeBus!.passengerPets, contains(PetColor.red));

      // Yellow Cat should go to Holding Dock slot 0
      expect(station.dockedPetCount, equals(1));
      expect(station.holdingDock[0].petColor, equals(PetColor.yellow));
      expect(result.dockOverflow, isFalse);
    });

    test('Auto-pulls waiting pets from Holding Dock when matching bus arrives', () {
      final station = BusStationManager();
      station.initializeBuses([
        BusData(id: 'red_bus', color: PetColor.red, name: 'Corgi Bus', capacity: 1),
        BusData(id: 'yellow_bus', color: PetColor.yellow, name: 'Cat Bus', capacity: 2),
      ]);

      // Yellow Cat is waiting on bench
      station.holdingDock[0].petColor = PetColor.yellow;
      expect(station.dockedPetCount, equals(1));

      // 1 Red Corgi freed -> fills Red bus (1/1) -> Red bus departs -> Yellow bus arrives!
      final freed = [
        const FreedPetInfo(row: 0, col: 0, color: PetColor.red),
      ];

      station.extractAndSortPassengers(freed);

      // Yellow bus is now active and immediately pulled Yellow Cat from bench!
      expect(station.activeBus!.color, equals(PetColor.yellow));
      expect(station.activeBus!.currentPassengers, equals(1));
      expect(station.holdingDock[0].isEmpty, isTrue); // Seat freed!
    });

    test('Triggers dockOverflow when all 5 seats are occupied and off-color pet arrives', () {
      final station = BusStationManager();
      station.initializeBuses([
        BusData(id: 'red_bus', color: PetColor.red, name: 'Corgi Bus', capacity: 4),
      ]);

      // Fill all 5 dock seats
      for (int i = 0; i < 5; i++) {
        station.holdingDock[i].petColor = PetColor.blue;
      }
      expect(station.isDockFull, isTrue);

      // Off-color pet arrives
      final freed = [
        const FreedPetInfo(row: 0, col: 0, color: PetColor.green),
      ];

      final result = station.extractAndSortPassengers(freed);
      expect(result.dockOverflow, isTrue);
    });
  });

  group('SmartSpawner Tests', () {
    test('Generates 3 shapes with bus color matching and Mercy Rule', () {
      final spawner = SmartSpawner();
      final redBus = BusData(id: 'b1', color: PetColor.red, name: 'Corgi', capacity: 3);

      spawner.generateNewBatch(
        availableColors: [PetColor.red, PetColor.yellow, PetColor.blue],
        activeBus: redBus,
        nextBus: null,
        emptyBoardCells: 12, // <= 16: Mercy Rule active!
      );

      expect(spawner.nextShapes.length, equals(3));
      expect(spawner.activeShapes.length, equals(3));

      // Test rotation
      final original = spawner.nextShapes[0]!.clone();
      spawner.rotateAllShapes();
      expect(spawner.nextShapes[0]!.rotation, equals((original.rotation + 90) % 360));
    });
  });

  group('LevelGenerator 200 Levels Tests', () {
    test('Generates valid levels across all 5 chapters', () {
      final lvl1 = LevelGenerator.getLevel(1);
      expect(lvl1.chapter, equals(1));
      expect(lvl1.availableColors.length, equals(2));

      final lvl50 = LevelGenerator.getLevel(50);
      expect(lvl50.chapter, equals(2));
      expect(lvl50.availableColors.length, equals(3));

      final lvl100 = LevelGenerator.getLevel(100);
      expect(lvl100.chapter, equals(3));
      expect(lvl100.availableColors.length, equals(4));

      final lvl150 = LevelGenerator.getLevel(150);
      expect(lvl150.chapter, equals(4));
      expect(lvl150.availableColors.length, equals(5));

      final lvl200 = LevelGenerator.getLevel(200);
      expect(lvl200.chapter, equals(5));
      expect(lvl200.buses.isNotEmpty, isTrue);
    });
  });

  group('Section 5 In-Match Upgrade & LiveOps Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Rainbow Express bus accepts all pet colors', () {
      final bus = BusData(
        id: 'rainbow_1',
        color: PetColor.red,
        name: '🌈 Rainbow Express',
        capacity: 4,
        isRainbow: true,
      );

      for (final color in PetColor.values) {
        expect(bus.accepts(color), isTrue);
      }
    });

    test('Holding dock capacity expansion and rescue in ReviveController', () {
      final station = BusStationManager();
      expect(station.dockCapacity, equals(5));

      // Fill dock
      for (int i = 0; i < 5; i++) {
        station.holdingDock[i].petColor = PetColor.blue;
      }

      final revive = ReviveController();
      final result = revive.executeDockOverflowRevive(busStation: station);

      expect(result.success, isTrue);
      expect(station.dockCapacity, equals(6)); // VIP slot added
      expect(station.holdingDock[5].isVip, isTrue);
      // 3 pets should have been rescued
      final remaining = station.holdingDock.where((s) => s.petColor != null).length;
      expect(remaining, equals(2));
    });

    test('Grid lock revive clears 2 most crowded rows and fills tray with 1x1 matching blocks', () {
      final engine = GridEngine();
      final spawner = SmartSpawner();
      final revive = ReviveController();

      // Row 0 has 5 items, Row 1 has 4 items
      for (int c = 0; c < 5; c++) {
        engine.cells[0][c].petColor = PetColor.red;
      }
      for (int c = 0; c < 4; c++) {
        engine.cells[1][c].petColor = PetColor.yellow;
      }

      final result = revive.executeGridLockRevive(
        gridEngine: engine,
        smartSpawner: spawner,
        activeBusColor: PetColor.yellow,
      );

      expect(result.success, isTrue);
      expect(engine.cells[0][0].petColor, isNull);
      expect(engine.cells[1][0].petColor, isNull);

      // Next shapes are 3 single 1x1 yellow blocks
      expect(spawner.nextShapes.length, equals(3));
      for (int i = 0; i < 3; i++) {
        final shape = spawner.nextShapes[i]!;
        expect(shape.width, equals(1));
        expect(shape.height, equals(1));
        expect(shape.tiles.first.petColor, equals(PetColor.yellow));
      }
    });

    test('WinStreakManager records wins and updates tiers', () async {
      final streak = WinStreakManager.instance;
      await streak.init();
      await streak.resetStreak();

      expect(streak.streakTier, equals(0));
      expect(streak.dockCapacity, equals(5));
      expect(streak.startingCompassCharges, equals(0));

      await streak.recordWin(); // 1 win -> Tier 1
      expect(streak.streakTier, equals(1));
      expect(streak.startingCompassCharges, equals(1));
      expect(streak.dockCapacity, equals(5));

      await streak.recordWin(); // 2 wins -> Tier 2
      expect(streak.streakTier, equals(2));
      expect(streak.dockCapacity, equals(6));

      await streak.recordWin(); // 3 wins -> Tier 3
      expect(streak.streakTier, equals(3));
      expect(streak.firstBusIsRainbow, isTrue);
      expect(streak.startingHammerCharges, equals(1));

      await streak.resetStreak();
      expect(streak.streakTier, equals(0));
    });

    test('BusRushRaceService tracks player buses and rank', () async {
      final race = BusRushRaceService.instance;
      await race.init();

      expect(race.targetBuses, equals(15));
      final rankBefore = race.getPlayerRank();
      expect(rankBefore, inInclusiveRange(1, 5));

      await race.recordPlayerBuses(20);
      expect(race.playerBuses, greaterThanOrEqualTo(15));
      expect(race.isPlayerWinner, isTrue);
      expect(race.getPlayerRank(), equals(1));
    });
  });
}

