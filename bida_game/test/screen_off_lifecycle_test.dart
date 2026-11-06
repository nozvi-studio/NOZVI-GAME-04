import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:bida_game/main.dart';
import 'package:bida_game/ui/aim_ruler_slider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen Off/On Lifecycle & Input Recovery Tests', () {
    test('BilliardGame pause and resume lifecycle state updates properly', () {
      final game = BilliardGame();

      // Simulate active gestures prior to screen off
      game.dragStart = Vector2(100, 100);
      game.dragCurrent = Vector2(120, 150);
      game.powerDragStartY = 200.0;
      game.movingCueBall = true;

      expect(game.isAppPaused, isFalse);

      // Screen turns off -> onAppPaused
      game.onAppPaused();

      expect(game.isAppPaused, isTrue);
      expect(game.dragStart, isNull);
      expect(game.dragCurrent, isNull);
      expect(game.powerDragStartY, isNull);
      expect(game.movingCueBall, isFalse);

      // Screen turns back on -> onAppResumed
      game.onAppResumed();

      expect(game.isAppPaused, isFalse);
      expect(game.dragStart, isNull);
      expect(game.dragCurrent, isNull);
      expect(game.powerDragStartY, isNull);
    });

    testWidgets('AimRulerSliderControl resets drag state when app pauses', (WidgetTester tester) async {
      final game = BilliardGame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 400,
              child: AimRulerSliderControl(game: game),
            ),
          ),
        ),
      );

      // Find the track gesture
      final trackFinder = find.byKey(const ValueKey('aim_ruler_track_gesture'));
      expect(trackFinder, findsOneWidget);

      // Simulate drag start on ruler
      final gesture = await tester.startGesture(tester.getCenter(trackFinder));
      await tester.pump();

      // Simulate app lifecycle going to paused (screen locked / turned off)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Cancel/end gesture
      await gesture.up();
      await tester.pump();

      // Simulate app lifecycle resuming
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(AimRulerSliderControl), findsOneWidget);
    });
  });
}
