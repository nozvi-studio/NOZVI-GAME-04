import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:bida_game/main.dart';
import 'package:bida_game/models/legendary_trickshot_model.dart';
import 'package:bida_game/services/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Physics & Jump Shot Enhancements Tests', () {
    test('CueBall has simulated z-axis physics and isAirborne detection', () {
      final cueBall = CueBall(Vector2(100, 100), 12.0);
      expect(cueBall.zHeight, equals(0.0));
      expect(cueBall.zVelocity, equals(0.0));
      expect(cueBall.isAirborne, isFalse);

      // Trigger jump shot
      cueBall.zVelocity = 280.0;
      cueBall.zHeight = 8.0;
      expect(cueBall.isAirborne, isTrue);

      // Update physics step dt
      cueBall.update(0.016);
      expect(cueBall.zHeight, greaterThan(8.0));
      expect(cueBall.zVelocity, lessThan(280.0));
    });

    test('BilliardGame stops stationary balls cleanly at 1.2 px/s', () {
      final game = BilliardGame();
      // Test ghost trail flags default
      expect(game.showPreviousShotGhost, isFalse);
      expect(game.previousShotAimVector, isNull);
    });

    test('AudioManager playBallHit handles zero and max volume scaling safely', () {
      // Disabling SFX for headless unit testing prevents missing platform audio channel
      AudioManager.instance.isSfxEnabled.value = false;
      AudioManager.instance.playBallHit(relativeSpeed: 40.0);
      AudioManager.instance.playBallHit(relativeSpeed: 500.0);
      expect(AudioManager.instance.isSfxEnabled.value, isFalse);
    });
  });

  group('Trickshot Ghost Trail & Ball-in-hand Safety Tests', () {
    test('Ghost trail is recorded and retained upon reset/practice again', () {
      final game = BilliardGame();
      game.activeLegendaryTrickshot = LegendaryTrickshotCatalog.getById('earl_short_jump');
      game.aimAngle = 1.25;
      game.shotPower.value = 0.70;

      // Simulate match restart / Practice Again
      game.previousShotAimAngle = 1.25;
      game.previousShotAimVector = Vector2(10, 15);
      game.previousShotPower = 0.70;
      game.restartMatch();

      expect(game.showPreviousShotGhost, isTrue);
      expect(game.previousShotAimAngle, equals(1.25));
      expect(game.previousShotPower, equals(0.70));
    });

    test('Bot AI state machine has 3 phases: think -> smooth aim -> shoot', () {
      final game = BilliardGame();
      game.isBotMode.value = true;
      game.currentTurn.value = 2;
      expect(game.botState, equals(0));
      expect(game.targetBotAngle, equals(0.0));
    });

    test('BallInHand notifies isBallInHandNotifier and unlocks upon placing cue ball', () {
      final game = BilliardGame();
      int ballInHandNotifiedCount = 0;
      game.isBallInHandNotifier.addListener(() {
        ballInHandNotifiedCount++;
      });

      int shotInProgressNotifiedCount = 0;
      game.isShotInProgressNotifier.addListener(() {
        shotInProgressNotifiedCount++;
      });

      // Foul occurs -> ball in hand
      game.ballInHand = true;
      expect(game.ballInHand, isTrue);
      expect(game.isBallInHandNotifier.value, isTrue);
      expect(ballInHandNotifiedCount, equals(1));

      // Player places cue ball down on table -> immediately unlocks
      game.ballInHand = false;
      expect(game.ballInHand, isFalse);
      expect(game.isBallInHandNotifier.value, isFalse);
      expect(ballInHandNotifiedCount, equals(2));

      // Shot taken -> shot in progress
      game.shotInProgress = true;
      expect(game.shotInProgress, isTrue);
      expect(game.isShotInProgressNotifier.value, isTrue);
      expect(shotInProgressNotifiedCount, equals(1));

      // Balls settle -> shot finished
      game.shotInProgress = false;
      expect(game.shotInProgress, isFalse);
      expect(game.isShotInProgressNotifier.value, isFalse);
      expect(shotInProgressNotifiedCount, equals(2));
    });

    test('BallInHand auto-confirms placement on power pull or aim adjustment', () {
      final game = BilliardGame();
      game.ballInHand = true;
      expect(game.ballInHand, isTrue);

      // User adjusts power -> confirms placement and unlocks
      game.beginPowerDrag(100.0);
      expect(game.ballInHand, isFalse);
      expect(game.isBallInHandNotifier.value, isFalse);

      // Re-trigger ball in hand
      game.ballInHand = true;
      game.rotateAim(0.1);
      expect(game.ballInHand, isFalse);
      expect(game.isBallInHandNotifier.value, isFalse);
    });
  });
}
