import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bida_game/models/cue_model.dart';
import 'package:bida_game/models/bot_stage_model.dart';
import 'package:bida_game/models/daily_puzzle_model.dart';
import 'package:bida_game/models/legendary_trickshot_model.dart';
import 'package:bida_game/services/progression_service.dart';
import 'package:flame/game.dart';
import 'package:bida_game/ui/player_profile_bar.dart';
import 'package:bida_game/ui/cue_power_slider.dart';
import 'package:bida_game/ui/aim_ruler_slider.dart';
import 'package:bida_game/ui/cue_shop_dialog.dart';
import 'package:bida_game/services/online_multiplayer_service.dart';
import 'package:bida_game/services/language_service.dart';
import 'package:bida_game/models/tournament_model.dart';
import 'package:bida_game/models/achievement_model.dart';
import 'package:bida_game/models/medal_model.dart';
import 'package:bida_game/ui/billiard_vfx_component.dart';
import 'package:bida_game/models/table_skin_model.dart';
import 'package:bida_game/ui/table_shop_dialog.dart';
import 'package:bida_game/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.init();
  });

  group('Cue Catalog & Stats Scaling Tests', () {
    test('Catalog contains 7 cues with valid attributes', () {
      final cues = CueCatalog.allCues;
      expect(cues.length, equals(13));

      final standard = CueCatalog.getById('standard_cue');
      expect(standard.isFree, isTrue);
      expect(standard.requiredLevel, equals(1));

      final dragon = CueCatalog.getById('dragon_god');
      expect(dragon.rarity, equals(CueRarity.legendary));
      expect(dragon.requiredLevel, equals(60));
      expect(dragon.priceDiamonds, equals(1500));
    });

    test('Cue stats scale from Level 1 to Level 10', () {
      final cue = CueCatalog.getById('titan_striker');
      final statLv1 = cue.getStatsForLevel(1);
      final statLv5 = cue.getStatsForLevel(5);
      final statLv10 = cue.getStatsForLevel(10);

      expect(statLv5.force, greaterThan(statLv1.force));
      expect(statLv10.force, greaterThan(statLv5.force));

      expect(cue.getForceMultiplier(10), greaterThan(cue.getForceMultiplier(1)));
      expect(cue.getAimMultiplier(10), greaterThan(cue.getAimMultiplier(1)));
      expect(cue.getSpinMultiplier(10), greaterThan(cue.getSpinMultiplier(1)));
    });

    test('Upgrade cost increases with level', () {
      final cue = CueCatalog.getById('frostbite');
      final costLv1 = cue.getUpgradeCostCoins(1);
      final costLv2 = cue.getUpgradeCostCoins(2);
      expect(costLv2, greaterThan(costLv1));
      expect(cue.getUpgradeCostCoins(10), equals(0)); // Max level cost is 0
    });
  });

  group('Bot Stage Campaign Catalog Tests', () {
    test('BotStageCatalog contains 10 progressive stages across 4 tiers', () {
      final stages = BotStageCatalog.stages;
      expect(stages.length, equals(10));

      final stage1 = stages[0];
      final stage10 = stages[9];

      expect(stage1.stageNumber, equals(1));
      expect(stage1.tierName, contains('Đồng'));
      expect(stage10.stageNumber, equals(10));
      expect(stage10.tierName, contains('Kim Cương'));

      // Stage 10 has higher accuracy than stage 1
      expect(stage1.aimErrorRad, greaterThan(stage10.aimErrorRad));
      expect(stage10.powerAccuracy, greaterThan(stage1.powerAccuracy));

      // High stages use advanced AI tricks
      expect(stage1.useSpin, isFalse);
      expect(stage10.useSpin, isTrue);
      expect(stage10.useSafetyShot, isTrue);
      expect(stage10.useScratchPrevention, isTrue);
    });
  });

  group('Legendary Trickshot Master Tests', () {
    test('Catalog contains 8 famous world trickshots with valid targets', () {
      final shots = LegendaryTrickshotCatalog.trickshots;
      expect(shots.length, greaterThanOrEqualTo(8));

      // Contains legendary players
      expect(shots.any((s) => s.playerName.contains('Efren')), isTrue);
      expect(shots.any((s) => s.playerName.contains('Ronnie')), isTrue);
      expect(shots.any((s) => s.playerName.contains('Shane')), isTrue);
      expect(shots.any((s) => s.playerName.contains('Hoàng')), isTrue);
      expect(shots.any((s) => s.playerName.contains('Florian')), isTrue);

      for (final shot in shots) {
        expect(shot.rewardCoins, greaterThan(0));
        expect(shot.rewardXP, greaterThan(0));
        expect(shot.balls.any((b) => b.ballNumber == shot.targetBallNumber), isTrue);
        expect(shot.cueBallNormX, inInclusiveRange(0.05, 0.95));
        expect(shot.cueBallNormY, inInclusiveRange(0.05, 0.95));
      }
    });

    test('ProgressionService completes trickshot and records progress', () {
      final service = ProgressionService.instance;
      final shot = LegendaryTrickshotCatalog.trickshots.first;

      expect(service.isTrickshotCompleted(shot.id), isFalse);
      final initialCoins = service.coins;
      final reward = service.completeLegendaryTrickshot(shot);

      expect(service.isTrickshotCompleted(shot.id), isTrue);
      expect(reward.earnedCoins, equals(shot.rewardCoins));
      expect(reward.earnedXP, equals(shot.rewardXP));
      expect(service.coins, greaterThanOrEqualTo(initialCoins + shot.rewardCoins));
    });

    test('All 8 legendary trickshots configure table layout correctly without default triangle rack', () {
      final shots = LegendaryTrickshotCatalog.trickshots;
      for (final shot in shots) {
        gameInstance.startLegendaryTrickshot(shot);
        expect(gameInstance.activeLegendaryTrickshot, equals(shot));
        expect(gameInstance.breakShot, isFalse);

        if (gameInstance.hasGameLoaded) {
          final participatingNumbers = shot.balls.map((b) => b.ballNumber).toSet();
          for (final ball in gameInstance.poolBalls) {
            if (participatingNumbers.contains(ball.number)) {
              expect(ball.isSunk, isFalse, reason: 'Ball ${ball.number} should be active on table for ${shot.id}');
              expect(ball.initialPosition.x, greaterThan(-500), reason: 'Ball ${ball.number} must be on table');
            } else {
              expect(ball.isSunk, isTrue, reason: 'Non-participating ball ${ball.number} should be marked sunk');
            }
          }
        }
      }
    });

    test('Table resize preserves legendary trickshot preset without reverting to default rack', () {
      final shot = LegendaryTrickshotCatalog.trickshots[2]; // Ronnie O'Sullivan
      gameInstance.startLegendaryTrickshot(shot);

      if (gameInstance.hasGameLoaded) {
        // Trigger table resize
        gameInstance.onGameResize(Vector2(800, 450));
        expect(gameInstance.activeLegendaryTrickshot, equals(shot));
        expect(gameInstance.breakShot, isFalse);

        final participating = shot.balls.map((b) => b.ballNumber).toSet();
        for (final ball in gameInstance.poolBalls) {
          if (participating.contains(ball.number)) {
            expect(ball.isSunk, isFalse);
          } else {
            expect(ball.isSunk, isTrue);
          }
        }
      }
    });
  });

  group('Daily Puzzle Generator Tests', () {
    test('DailyPuzzleModel generates consistent seeded layout for given date', () {
      final date = DateTime(2026, 9, 23);
      final puzzle1 = DailyPuzzleModel.generateForDate(date);
      final puzzle2 = DailyPuzzleModel.generateForDate(date);

      expect(puzzle1.dateKey, equals('2026-09-23'));
      expect(puzzle1.dateKey, equals(puzzle2.dateKey));
      expect(puzzle1.title, equals(puzzle2.title));
      expect(puzzle1.balls.length, equals(puzzle2.balls.length));
      expect(puzzle1.maxShotsAllowed, greaterThanOrEqualTo(1));
      expect(puzzle1.rewardCoins, greaterThan(0));
      expect(puzzle1.rewardXP, greaterThan(0));
    });
  });

  group('ProgressionService Logic & Rewards Tests', () {
    test('XP addition and Level Up rewards', () {
      final service = ProgressionService.instance;
      final initialLevel = service.playerLevel;
      final xpRequired = service.xpRequiredForNextLevel;

      final result = service.addXPAndCoins(
        xpGained: xpRequired + 10,
        coinsGained: 200,
      );

      expect(result.didLevelUp, isTrue);
      expect(service.playerLevel, equals(initialLevel + 1));
      expect(result.bonusDiamonds, greaterThan(0));
    });

    test('Bot stage completion unlocks next stage', () {
      final service = ProgressionService.instance;
      final stage1 = BotStageCatalog.getStage(1);

      expect(service.isBotStageUnlocked(1), isTrue);
      final reward = service.completeBotStage(stage1);

      expect(service.isBotStageCompleted(1), isTrue);
      expect(service.isBotStageUnlocked(2), isTrue);
      expect(reward.earnedCoins, equals(stage1.firstClearCoins));
      expect(reward.earnedXP, equals(stage1.firstClearXP));
    });

    test('Daily puzzle reward claim is recorded and prevented on duplicate claim', () {
      final service = ProgressionService.instance;
      final puzzle = DailyPuzzleModel.generateForDate(DateTime.now());

      final reward = service.claimDailyPuzzleReward(puzzle);
      expect(reward, isNotNull);
      expect(service.isDailyPuzzleCompletedToday(), isTrue);

      final secondClaim = service.claimDailyPuzzleReward(puzzle);
      expect(secondClaim, isNull);
    });

    test('Level requirement gates cue unlocking', () {
      final service = ProgressionService.instance;
      final standard = CueCatalog.getById('standard_cue');
      final dragon = CueCatalog.getById('dragon_god');

      expect(service.canUnlockCue(standard), isTrue);
      if (service.playerLevel < 60) {
        expect(service.canUnlockCue(dragon), isFalse);
      }
    });
  });

  group('Aim Ruler Slider Control Tests', () {
    test('aimAngle and aimAngleNotifier are synchronized', () {
      gameInstance.aimAngle = 1.25;
      expect(gameInstance.aimAngleNotifier.value, closeTo(1.25, 0.0001));

      gameInstance.aimAngleNotifier.value = 2.50;
      expect(gameInstance.aimAngle, closeTo(2.50, 0.0001));
    });

    test('Micro-step angle rotation scales precisely for millimeter aiming', () {
      final initialAngle = gameInstance.aimAngle;
      const microStep = 0.0045; // ~0.25 degrees (~1mm)
      gameInstance.rotateAim(microStep);

      expect(gameInstance.aimAngle, closeTo(initialAngle + microStep, 0.0001));
    });

    testWidgets('AimRulerSliderControl renders yellow 0° and vertical capsule track', (tester) async {
      gameInstance.startPlayerMatch();
      gameInstance.aimAngle = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 450,
              width: 80,
              child: AimRulerSliderControl(
                game: gameInstance,
                onOpenSpinDialog: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Kiểm tra chữ số 0° màu vàng ở đỉnh
      expect(find.text('0°'), findsOneWidget);

      // Kiểm tra rãnh trượt thước đo
      final trackFinder = find.byKey(const ValueKey('aim_ruler_track_gesture'));
      expect(trackFinder, findsOneWidget);

      // Kéo vuốt trên rãnh thước để xoay góc ngắm
      await tester.drag(trackFinder, const Offset(0, 60));
      await tester.pump();

      // Góc ngắm thay đổi
      expect(gameInstance.aimAngle, isNot(equals(0.0)));
    });
  });

  group('8-Ball & Group Targeting Tests', () {
    test('ballGroup correctly categorizes solids, stripes, and 8-ball as neutral', () {
      for (int i = 1; i <= 7; i++) {
        expect(gameInstance.ballGroup(i), equals(BallGroup.solids));
      }
      expect(gameInstance.ballGroup(8), isNull);
      for (int i = 9; i <= 15; i++) {
        expect(gameInstance.ballGroup(i), equals(BallGroup.stripes));
      }
    });

    test('getPlayerGroup accurately provides or infers player groups', () {
      gameInstance.playerGroups.clear();
      gameInstance.playerGroups[1] = BallGroup.solids;
      expect(gameInstance.getPlayerGroup(1), equals(BallGroup.solids));
      expect(gameInstance.getPlayerGroup(2), equals(BallGroup.stripes));

      gameInstance.playerGroups[1] = BallGroup.stripes;
      expect(gameInstance.getPlayerGroup(2), equals(BallGroup.solids));
    });
  });

  group('Lifecycle & Pre-load Safety Tests', () {
    test('Starting match modes before game is loaded does not throw LateInitializationError', () {
      expect(() => gameInstance.startPlayerMatch(), returnsNormally);
      expect(gameInstance.isBotMode.value, isFalse);
      expect(gameInstance.activeBotStage, isNull);

      final stage = BotStageCatalog.stages.first;
      expect(() => gameInstance.startBotStage(stage), returnsNormally);
      expect(gameInstance.isBotMode.value, isTrue);
      expect(gameInstance.activeBotStage, equals(stage));

      final puzzle = DailyPuzzleModel.generateForDate(DateTime.now());
      expect(() => gameInstance.startDailyPuzzle(puzzle), returnsNormally);
      expect(gameInstance.activeDailyPuzzle, equals(puzzle));

      expect(() => gameInstance.startLocalMultiplayer(), returnsNormally);
      expect(gameInstance.isLocalMultiplayer.value, isTrue);

      expect(() => gameInstance.resetCueSpin(), returnsNormally);
      expect(() => gameInstance.update(0.016), returnsNormally);
    });
  });

  group('Cue Power Pull-Down Slider Tests', () {
    test('setShotPower clamps precisely within valid bounds [0.05, 1.0]', () {
      gameInstance.setShotPower(0.0);
      expect(gameInstance.shotPower.value, closeTo(0.05, 0.0001));

      gameInstance.setShotPower(0.55);
      expect(gameInstance.shotPower.value, closeTo(0.55, 0.0001));

      gameInstance.setShotPower(1.50);
      expect(gameInstance.shotPower.value, closeTo(1.0, 0.0001));

      gameInstance.setShotPower(-0.2);
      expect(gameInstance.shotPower.value, closeTo(0.05, 0.0001));
    });

    testWidgets('CuePowerSliderControl renders yellow 0% and capsule with bottom circular button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 450,
              width: 80,
              child: CuePowerSliderControl(game: gameInstance),
            ),
          ),
        ),
      );
      await tester.pump();

      // Kiểm tra hiển thị % màu vàng ở đỉnh (mặc định 0%)
      expect(find.text('0%'), findsOneWidget);

      // Kiểm tra rãnh trượt con nhộng và nút tròn ở đáy
      expect(find.byKey(const ValueKey('cue_power_track_gesture')), findsOneWidget);
      expect(find.byKey(const ValueKey('cue_slider_bottom_button')), findsOneWidget);

      // Chạm nút tròn ở đáy
      await tester.tap(find.byKey(const ValueKey('cue_slider_bottom_button')));
      await tester.pump();
    });

    testWidgets('Dragging cue slider down and releasing invokes release-to-shoot', (tester) async {
      gameInstance.startPlayerMatch();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 450,
              width: 80,
              child: CuePowerSliderControl(game: gameInstance),
            ),
          ),
        ),
      );
      await tester.pump();

      // Kéo thanh trượt xuống
      final trackFinder = find.byKey(const ValueKey('cue_power_track_gesture'));
      expect(trackFinder, findsOneWidget);

      final topLeft = tester.getTopLeft(trackFinder);
      final gesture = await tester.startGesture(topLeft + const Offset(10, 10));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();

      // Lực cơ tăng lên khi kéo xuống
      expect(gameInstance.shotPower.value, greaterThan(0.05));

      // Thả tay ra (up)
      await gesture.up();
      await tester.pump();
    });

    test('Restarting match when balls are sunk/removed does not throw lifecycle event exception', () {
      gameInstance.startPlayerMatch();

      // Giả lập một số bi đã bị chìm vào lỗ
      for (int i = 0; i < gameInstance.poolBalls.length; i++) {
        if (i % 2 == 0) {
          gameInstance.poolBalls[i].isSunk = true;
        }
      }

      expect(() => gameInstance.restartMatch(), returnsNormally);
    });

    test('Equipping different cues updates ProgressionService.equippedCue dynamically', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'progression_owned_cues',
        jsonEncode({'standard_cue': 1, 'frostbite': 1, 'dragon_god': 1}),
      );
      await ProgressionService.instance.init();

      // Mặc định là standard_cue
      expect(ProgressionService.instance.equippedCue.id, equals('standard_cue'));

      // Trang bị Cơ Băng Phong
      ProgressionService.instance.equipCue('frostbite');
      expect(ProgressionService.instance.equippedCue.id, equals('frostbite'));
      expect(ProgressionService.instance.equippedCue.name, equals('Cơ Băng Phong'));
      expect(ProgressionService.instance.equippedCue.tipColor, isNotNull);
      expect(ProgressionService.instance.equippedCue.shaftColors, isNotEmpty);

      // Trang bị Cơ Rồng Vàng
      ProgressionService.instance.equipCue('dragon_god');
      expect(ProgressionService.instance.equippedCue.id, equals('dragon_god'));
      expect(ProgressionService.instance.equippedCue.name, equals('Cơ Đế Vương Rồng Vàng'));

      // Chuyển lại về standard_cue
      ProgressionService.instance.equipCue('standard_cue');
      expect(ProgressionService.instance.equippedCue.id, equals('standard_cue'));
    });
  });

  group('Mobile Main Menu UI Layout Tests', () {
    testWidgets('BilliardHome renders classic green felt card without overflow on mobile landscape (720x360)', (tester) async {
      tester.view.physicalSize = const Size(720, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: BilliardHome(),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và logo
      expect(find.text('8 POOL BILLIARDS'), findsOneWidget);
      expect(find.text('choose_match'.tr), findsOneWidget);

      // Kiểm tra các nút chế độ
      expect(find.text('P1 vs P2 (CÙNG MÁY)'), findsOneWidget);
      expect(find.textContaining('THẾ ĐÁNH HUYỀN THOẠI'), findsOneWidget);
      expect(find.text('ĐẤU MẠNG LOCAL'), findsOneWidget);
      expect(find.text('10 ẢI THỬ THÁCH BOT'), findsOneWidget);
      expect(find.text('THẾ BI HÀNG NGÀY'), findsOneWidget);

      // Kiểm tra thanh người chơi
      expect(find.byType(PlayerProfileBar), findsOneWidget);
    });

    testWidgets('BilliardHome renders cleanly without overflow on mobile portrait (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: BilliardHome(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8 POOL BILLIARDS'), findsOneWidget);
      expect(find.text('choose_match'.tr), findsOneWidget);
      expect(find.text('P1 vs P2 (CÙNG MÁY)'), findsOneWidget);
    });
  });

  group('Physics & Ball Racking Algorithms Tests', () {
    test('onGameResize recalculates ballRadius and table bounds dynamically', () {
      final game = BilliardGame();
      // Giả lập kích thước mobile 600x300
      game.onGameResize(Vector2(600, 300));
      expect(game.ballRadius, closeTo(300 * 0.0235, 0.01));
      expect(game.playAreaTopLeft.x, closeTo(600 * 0.0574, 0.01));
      expect(game.playAreaTopLeft.y, closeTo(300 * 0.1034, 0.01));

      // Giả lập xoay hoặc đổi kích thước mobile 800x400
      game.onGameResize(Vector2(800, 400));
      expect(game.ballRadius, closeTo(400 * 0.0235, 0.01));
      expect(game.playAreaTopLeft.x, closeTo(800 * 0.0574, 0.01));
      expect(game.playAreaTopLeft.y, closeTo(400 * 0.1034, 0.01));
    });

    test('safeCueBallPlacementPosition always stays inside table kitchen area', () {
      final game = BilliardGame();
      game.onGameResize(Vector2(800, 400));
      final pos = game.initialCueBallPosition;
      expect(pos.x, equals(800 * 0.25));
      expect(pos.y, equals(200));
    });
  });

  group('Shop In-Dialog Notification & Setting Bot Option Removal Tests', () {
    testWidgets('CueShopDialog displays in-shop error toast immediately when user cannot afford cue', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await ProgressionService.instance.init();
      ProgressionService.instance.addXPAndCoins(xpGained: 10000, coinsGained: 0);
      ProgressionService.instance.spendCoins(ProgressionService.instance.coins);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CueShopDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titanFinder = find.text('Cơ Titan Thép');
      expect(titanFinder, findsOneWidget);
      await tester.tap(titanFinder);
      await tester.pumpAndSettle();

      final buyButton = find.textContaining('MUA NGAY');
      expect(buyButton, findsOneWidget);

      await tester.ensureVisible(buyButton);
      await tester.pumpAndSettle();
      await tester.tap(buyButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Bạn không đủ Vàng để mua cây cơ này'), findsOneWidget);
    });
  });

  group('Multiplayer Cue Synchronization Tests', () {
    test('getActivePlayerCue dynamically displays active player cue on their turn', () {
      ProgressionService.instance.applyAdminPrivileges();

      final game = BilliardGame();
      game.isOnlineMultiplayer.value = true;

      // Giả lập Player 1 dùng cơ Titan Striker
      ProgressionService.instance.equipCue('titan_striker');

      // Giả lập Đối thủ dùng cơ Frostbite Lv 3
      OnlineMultiplayerService.instance.opponentCueId = 'frostbite';
      OnlineMultiplayerService.instance.opponentCueLevel = 3;

      // 1. Góc nhìn của Host (Player 1):
      OnlineMultiplayerService.instance.isHost = true;
      // Khi đến lượt P1 (currentTurn = 1) -> Thấy cơ P1 (Titan Striker)
      game.currentTurn.value = 1;
      final (cueP1TurnHost, _) = game.getActivePlayerCue();
      expect(cueP1TurnHost.id, equals('titan_striker'));

      // Khi đến lượt P2 (currentTurn = 2) -> Host thấy cơ P2 (Frostbite Lv 3)
      game.currentTurn.value = 2;
      final (cueP2TurnHost, lvlP2TurnHost) = game.getActivePlayerCue();
      expect(cueP2TurnHost.id, equals('frostbite'));
      expect(lvlP2TurnHost, equals(3));

      // 2. Góc nhìn của Guest (Player 2):
      OnlineMultiplayerService.instance.isHost = false;
      // Khi đến lượt P1 (currentTurn = 1) -> Guest thấy cơ P1 (Titan Striker Lv 5)
      game.currentTurn.value = 1;
      OnlineMultiplayerService.instance.opponentCueId = 'titan_striker';
      OnlineMultiplayerService.instance.opponentCueLevel = 5;
      final (cueP1TurnGuest, lvlP1TurnGuest) = game.getActivePlayerCue();
      expect(cueP1TurnGuest.id, equals('titan_striker'));
      expect(lvlP1TurnGuest, equals(5));

      // Khi đến lượt P2 (currentTurn = 2) -> Guest thấy cơ mình trang bị
      ProgressionService.instance.equipCue('frostbite');
      game.currentTurn.value = 2;
      final (cueP2TurnGuest, _) = game.getActivePlayerCue();
      expect(cueP2TurnGuest.id, equals('frostbite'));
    });
  });

  group('Online Multiplayer Real-Time Reconnection Tests', () {
    test('resumeOnlineMultiplayer preserves live turn, ballInHand and groups without restart', () {
      final game = BilliardGame();
      game.playerGroups[1] = BallGroup.solids;
      game.playerGroups[2] = BallGroup.stripes;
      game.currentTurn.value = 2;
      game.ballInHand = true;

      // Giả lập kết nối lại phòng
      final liveState = {
        'lastBalls': [
          {'num': 0, 'nx': 0.3, 'ny': 0.4, 'sunk': false},
          {'num': 1, 'nx': 0.7, 'ny': 0.8, 'sunk': false},
        ],
        'cueBall': {'nx': 0.3, 'ny': 0.4, 'sunk': false},
        'currentTurn': 2,
        'ballInHand': true,
        'p1Group': 'solids',
        'p2Group': 'stripes',
      };

      game.resumeOnlineMultiplayer(
        roomId: '123456',
        isHost: true,
        state: liveState,
      );

      expect(game.isOnlineMultiplayer.value, isTrue);
      expect(game.currentTurn.value, equals(2));
      expect(game.ballInHand, isTrue);
      expect(game.playerGroups[1], equals(BallGroup.solids));
      expect(game.playerGroups[2], equals(BallGroup.stripes));
    });
  });

  group('Real-Time Physics & Home Exit Lifecycle Tests', () {
    test('onPanCancel resets movingCueBall and clears drag state without stuck lock', () {
      final game = BilliardGame();
      game.movingCueBall = true;
      game.dragStart = Vector2(100, 100);
      game.dragCurrent = Vector2(150, 150);

      game.onPanCancel();

      expect(game.movingCueBall, isFalse);
      expect(game.dragStart, isNull);
      expect(game.dragCurrent, isNull);
    });

    test('onAppPaused records timestamp and onAppResumed executes without crashing', () {
      final game = BilliardGame();
      expect(game.isAppPaused, isFalse);

      game.onAppPaused();
      expect(game.isAppPaused, isTrue);

      // Giả lập người chơi mở lại app
      game.onAppResumed();
      expect(game.isAppPaused, isFalse);
    });

    testWidgets('BilliardHome mounts GameWidget and preserves in Offstage upon exiting to menu', (tester) async {
      tester.view.physicalSize = const Size(800, 450);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: BilliardHome(),
        ),
      );
      await tester.pumpAndSettle();

      // Main menu hiển thị ban đầu
      expect(find.byType(BilliardHome), findsOneWidget);
      expect(find.text('P1 vs P2 (CÙNG MÁY)'), findsOneWidget);

      // Tapping P1 vs P2 bắt đầu ván đấu
      await tester.tap(find.text('P1 vs P2 (CÙNG MÁY)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Offstage GameWidget hiện diện trong cây widget để duy trì real-time
      expect(find.byType(Offstage), findsWidgets);
    });
  });

  group('Tournament 5 Brackets Catalog & Progression Tests', () {
    test('TournamentCatalog contains exactly 5 brackets and Bracket 5 is Grand Finals', () {
      final brackets = TournamentCatalog.brackets;
      expect(brackets.length, equals(5));

      final bracket1 = brackets[0];
      expect(bracket1.bracketNumber, equals(1));
      expect(bracket1.roundName, equals('Round of 32'));

      final bracket5 = brackets[4];
      expect(bracket5.bracketNumber, equals(5));
      expect(bracket5.roundName, equals('Grand Championship Finals'));
      expect(bracket5.opponentName, contains('Long Hoàng Vũ'));
      expect(bracket5.bonusMedalId, equals('tournament_champion'));
      expect(bracket5.coinReward, equals(15000));
      expect(bracket5.xpReward, equals(2500));
    });

    test('completeTournamentBracket advances from 1 to 4, and awards championship on 5', () async {
      await ProgressionService.instance.init();
      ProgressionService.instance.resetTournament();
      expect(ProgressionService.instance.currentTournamentBracket, equals(1));

      // Win Bracket 1 -> Advances to Bracket 2
      final b1 = TournamentCatalog.getByBracket(1);
      final res1 = ProgressionService.instance.completeTournamentBracket(b1);
      expect(ProgressionService.instance.currentTournamentBracket, equals(2));
      expect(res1.customMessage, contains('TIẾN VÀO BRACKET 2'));

      // Win Bracket 5 -> Crowned Grand Champion, resets to 1
      final b5 = TournamentCatalog.getByBracket(5);
      final res5 = ProgressionService.instance.completeTournamentBracket(b5);
      expect(ProgressionService.instance.currentTournamentBracket, equals(1));
      expect(res5.customMessage, contains('QUÁN QUÂN VÔ ĐỊCH TOURNAMENT 5 BRACKETS'));
      expect(ProgressionService.instance.isMedalUnlocked('tournament_champion'), isTrue);
    });
  });

  group('Billiard VFX Component GPU Optimization Tests', () {
    test('BilliardVfxComponent handles particle lifecycle, capping and clearAll without lag or error', () {
      final vfx = BilliardVfxComponent();

      // Test idle fast early-return
      vfx.update(0.016);

      // Add high-speed collision
      for (int i = 0; i < 20; i++) {
        vfx.addBallCollision(Vector2(100.0 + i, 200.0), 500.0);
      }

      // Add chalk puff
      vfx.addCueChalkPuff(
        tipPos: Vector2(150, 150),
        shotDirection: Vector2(1, 0),
        shotSpeed: 1000.0,
      );

      // Add rail impact and pocket drop
      vfx.addRailImpact(
        ballPos: Vector2(50, 50),
        wallStart: Vector2(0, 50),
        wallEnd: Vector2(100, 50),
        speed: 300.0,
      );
      vfx.addPocketDrop(Vector2(20, 20));

      // Add motion trails
      vfx.recordBallPosition(0, Vector2(200, 200), 800.0);
      vfx.recordBallPosition(1, Vector2(300, 300), 600.0);

      // Update simulation
      vfx.update(0.05);

      // Clear trail when ball stops or sinks
      vfx.clearBallTrail(0);
      vfx.clearBallTrail(1);

      // Clear all
      vfx.clearAll();
      vfx.update(0.016);
    });
  });

  group('Expanded 100 Achievements and Medals Catalog Tests', () {
    test('AchievementCatalog contains 60 achievements with valid fields', () {
      final achs = AchievementCatalog.allAchievements;
      expect(achs.length, equals(60));

      final uniqueIds = <String>{};
      for (final a in achs) {
        expect(uniqueIds.add(a.id), isTrue, reason: 'Achievement ID ${a.id} should be unique');
        expect(a.title.isNotEmpty, isTrue);
        expect(a.description.isNotEmpty, isTrue);
        expect(a.rewardXP, greaterThan(0));
      }
    });

    test('MedalCatalog contains 40 medals across 5 rarities with unique IDs', () {
      final medals = MedalCatalog.allMedals;
      expect(medals.length, equals(40));

      final uniqueIds = <String>{};
      for (final m in medals) {
        expect(uniqueIds.add(m.id), isTrue, reason: 'Medal ID ${m.id} should be unique');
        expect(m.name.isNotEmpty, isTrue);
        expect(m.description.isNotEmpty, isTrue);
        expect(m.unlockRequirement.isNotEmpty, isTrue);
        expect(m.rarity.gradientColors.length, greaterThanOrEqualTo(2));
      }

      // Verify combined count is exactly 100
      expect(AchievementCatalog.allAchievements.length + MedalCatalog.allMedals.length, equals(100));
    });

    test('LanguageService translates achievements and medals across all languages', () {
      final ach = AchievementCatalog.allAchievements.first;
      final medal = MedalCatalog.allMedals.first;

      for (final lang in ['vi', 'en', 'zh', 'ja', 'ko']) {
        LanguageService.instance.setLanguage(AppLanguage.fromCode(lang));
        expect(ach.localizedTitle.isNotEmpty, isTrue);
        expect(ach.localizedDescription.isNotEmpty, isTrue);
        expect(medal.localizedName.isNotEmpty, isTrue);
        expect(medal.localizedDescription.isNotEmpty, isTrue);
        expect(medal.localizedRequirement.isNotEmpty, isTrue);
        expect(medal.rarity.label.isNotEmpty, isTrue);
      }
      LanguageService.instance.setLanguage(AppLanguage.vi);
    });

    test('checkAchievementsAndMedals unlocks milestone tiers automatically', () async {
      await ProgressionService.instance.init();
      ProgressionService.instance.resetTournament();

      // Add wins and coins
      ProgressionService.instance.addCoins(100000);
      for (int i = 0; i < 50; i++) {
        ProgressionService.instance.recordWin();
      }
      ProgressionService.instance.checkAchievementsAndMedals();

      expect(ProgressionService.instance.isAchievementUnlocked('first_win'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('win_streak_3'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('win_10'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('win_25'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('win_50'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('rich_player'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('billiard_god'), isTrue);

      expect(ProgressionService.instance.isMedalUnlocked('bronze_champion'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('veteran_striker'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('centurion_victor'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('golden_treasury'), isTrue);
    });

    test('Admin privileges unlock all achievements and medals', () {
      ProgressionService.instance.applyAdminPrivileges();
      ProgressionService.instance.checkAchievementsAndMedals();

      expect(ProgressionService.instance.playerLevel, equals(99));
      expect(ProgressionService.instance.coins, equals(9999999));
      expect(ProgressionService.instance.totalWins, equals(999));

      // Key high-tier achievements & medals are unlocked
      expect(ProgressionService.instance.isAchievementUnlocked('reach_level_50'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('billiard_emperor'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('cue_arsenal_full'), isTrue);
      expect(ProgressionService.instance.isAchievementUnlocked('tournament_champion_legend'), isTrue);

      expect(ProgressionService.instance.isMedalUnlocked('bot_overlord'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('immortal_sovereign'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('cue_collector_mythic'), isTrue);
      expect(ProgressionService.instance.isMedalUnlocked('trickshot_immortal'), isTrue);
    });
  });

  group('Table Skin Shop & Realistic Spin Physics Tests', () {
    test('TableSkinCatalog contains exactly 20 distinct pool table skins', () {
      expect(TableSkinCatalog.allTables.length, equals(20));

      final ids = <String>{};
      for (final table in TableSkinCatalog.allTables) {
        expect(ids.add(table.id), isTrue, reason: 'Duplicate table ID: ${table.id}');
        expect(table.name.isNotEmpty, isTrue);
        expect(table.description.isNotEmpty, isTrue);
        expect(table.clothPrimary, isNotNull);
        expect(table.clothSecondary, isNotNull);
        expect(table.railColor, isNotNull);
        expect(table.railAccentColor, isNotNull);
        expect(table.pocketColor, isNotNull);
      }
    });

    test('Table skins translate names and descriptions across all 5 languages', () {
      final sampleTable = TableSkinCatalog.allTables.first;

      for (final lang in ['vi', 'en', 'zh', 'ja', 'ko']) {
        LanguageService.instance.setLanguage(AppLanguage.fromCode(lang));
        expect(sampleTable.localizedName.isNotEmpty, isTrue);
        expect(sampleTable.localizedDescription.isNotEmpty, isTrue);
        expect(sampleTable.rarity.label.isNotEmpty, isTrue);
      }
      LanguageService.instance.setLanguage(AppLanguage.vi);
    });

    test('ProgressionService table purchase, level requirement and equip mechanics work', () async {
      ProgressionService.instance.resetToDefault(save: false);
      ProgressionService.instance.addCoins(20000);
      ProgressionService.instance.addDiamonds(50);

      // Default table is classic_green
      expect(ProgressionService.instance.equippedTableId, equals('classic_green'));
      expect(ProgressionService.instance.isTableOwned('classic_green'), isTrue);
      expect(ProgressionService.instance.isTableEquipped('classic_green'), isTrue);

      // Buy royal_navy with coins (level 2 requirement, 2500 coins)
      final navyTable = TableSkinCatalog.getById('royal_navy');
      if (ProgressionService.instance.playerLevel < 2) {
        expect(ProgressionService.instance.canUnlockTable(navyTable), isFalse);
      }

      // Add XP to reach level 2
      ProgressionService.instance.addXPAndCoins(xpGained: 500, coinsGained: 0);
      expect(ProgressionService.instance.canUnlockTable(navyTable), isTrue);

      final bought = ProgressionService.instance.buyTable(navyTable);
      expect(bought, isTrue);
      expect(ProgressionService.instance.isTableOwned('royal_navy'), isTrue);
      expect(ProgressionService.instance.isTableEquipped('royal_navy'), isTrue);
      expect(ProgressionService.instance.equippedTable.id, equals('royal_navy'));

      // Equip back to classic_green
      final equippedBack = ProgressionService.instance.equipTable('classic_green');
      expect(equippedBack, isTrue);
      expect(ProgressionService.instance.equippedTableId, equals('classic_green'));
    });

    test('Admin privileges unlock all 20 tables and equip dragon_emperor', () {
      ProgressionService.instance.applyAdminPrivileges();

      expect(ProgressionService.instance.equippedTableId, equals('dragon_emperor'));
      expect(ProgressionService.instance.ownedTableIds.length, equals(20));
      for (final table in TableSkinCatalog.allTables) {
        expect(ProgressionService.instance.isTableOwned(table.id), isTrue);
      }
    });

    testWidgets('TableShopDialog renders on mobile layout without errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 360));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TableShopDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TableShopDialog), findsOneWidget);
      expect(find.text('CỬA HÀNG BÀN BIDA'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}



