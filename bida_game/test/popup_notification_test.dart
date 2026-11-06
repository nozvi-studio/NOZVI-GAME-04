import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuleMessagePopupBanner Tests', () {
    testWidgets('Notification appears as popup then fades away until it disappears', (tester) async {
      final game = gameInstance;
      game.rackOver = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RuleMessagePopupBanner(
                  ultraCompact: false,
                  upscale: 1.0,
                ),
              ],
            ),
          ),
        ),
      );

      // Trigger first notification: 'Lượt Player 1'
      game.ruleMessage.value = 'Lượt Player 1';
      await tester.pump(); // Start popup animation
      await tester.pump(const Duration(milliseconds: 260)); // Full popup entrance

      // Notification is visible
      expect(find.text('Lượt Player 1'), findsOneWidget);

      // Wait 1000ms: still within display duration (2000ms)
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Lượt Player 1'), findsOneWidget);

      // Wait remaining 1000ms (end of display duration) + 600ms (fade-out completes)
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 600));

      // Notification has completely faded away and disappeared
      expect(find.text('Lượt Player 1'), findsNothing);

      // Trigger second notification: 'Lượt Player 2' (as seen in user screenshot)
      game.ruleMessage.value = 'Lượt Player 2';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      // Second notification pops up
      expect(find.text('Lượt Player 2'), findsOneWidget);

      // Wait until it fades away and disappears
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Lượt Player 2'), findsNothing);
    });

    test('RuleMessageNotifier triggers notifyListeners even when identical message is assigned', () {
      final notifier = RuleMessageNotifier('Player 1');
      int notifyCount = 0;
      notifier.addListener(() {
        notifyCount++;
      });

      // Assign different value
      notifier.value = 'Lượt Player 2';
      expect(notifyCount, equals(1));
      expect(notifier.version, equals(1));

      // Assign identical value: should still notify listeners and increment version
      notifier.value = 'Lượt Player 2';
      expect(notifyCount, equals(2));
      expect(notifier.version, equals(2));
    });

    testWidgets('RackOver immediately dismisses notification', (tester) async {
      final game = gameInstance;
      game.rackOver = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RuleMessagePopupBanner(
                  ultraCompact: false,
                  upscale: 1.0,
                ),
              ],
            ),
          ),
        ),
      );

      game.ruleMessage.value = 'Foul - ball in hand';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('Foul - ball in hand'), findsOneWidget);

      // Game ends (rackOver)
      game.rackOver = true;
      game.matchVersion.value++;
      await tester.pump();

      // Immediately dismissed
      expect(find.text('Foul - ball in hand'), findsNothing);
    });
  });
}

