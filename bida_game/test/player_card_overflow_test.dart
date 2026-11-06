import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/main.dart';
import 'package:bida_game/services/language_service.dart';

void main() {
  group('Player Card & Control Bar Zero-Overflow Tests', () {
    testWidgets('Top Control Bar does not overflow on mobile landscape (800x360) with Chinese solids/stripes', (WidgetTester tester) async {
      LanguageService.instance.setLanguage(AppLanguage.zh);
      gameInstance.playerGroups[1] = BallGroup.solids;
      gameInstance.playerGroups[2] = BallGroup.stripes;
      gameInstance.groupVersion.value++;

      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        gameInstance.playerGroups.clear();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 360,
                child: Builder(
                  builder: (context) {
                    return buildControlBarForTesting(
                      context,
                      compact: true,
                      ultraCompact: false,
                      upscaleFactor: 0.96,
                      onHome: () {},
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
      expect(find.text('全色球 (1-7)'), findsOneWidget);
      expect(find.text('花色球 (9-15)'), findsOneWidget);
    });

    testWidgets('Player Card renders without overflow on ultra-compact mobile (640x320) with long names', (WidgetTester tester) async {
      LanguageService.instance.setLanguage(AppLanguage.zh);

      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 48,
              child: buildPlayerCardForTesting(
                'Super Long Master Name',
                Colors.blue,
                true,
                5,
                '全色球 (1-7)',
                [1, 2, 3, 4, 5, 6, 7],
                false,
                level: 99,
                coins: 999999,
                compact: true,
                ultraCompact: true,
                upscaleFactor: 0.90,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Lv.99'), findsOneWidget);
    });

    testWidgets('Player Card renders cleanly in Vietnamese and English', (WidgetTester tester) async {
      for (final lang in [AppLanguage.vi, AppLanguage.en]) {
        LanguageService.instance.setLanguage(lang);
        final label = lang == AppLanguage.vi ? 'Bi trơn (1-7)' : 'Solids (1-7)';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 58,
                child: buildPlayerCardForTesting(
                  'Player 1',
                  Colors.blue,
                  true,
                  2,
                  label,
                  [1, 2, 3, 4, 5, 6, 7],
                  false,
                  level: 3,
                  coins: 1500,
                  compact: true,
                  ultraCompact: false,
                  upscaleFactor: 0.96,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
