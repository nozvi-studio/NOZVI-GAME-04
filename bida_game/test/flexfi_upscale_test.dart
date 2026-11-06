import 'package:bida_game/main.dart';
import 'package:bida_game/services/progression_service.dart';
import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/ui/responsive_layout_helper.dart';

void main() {
  group('Flexfi Upscale & Foldable Architecture Tests', () {
    testWidgets('Galaxy Z Fold Unfolded (Square-ish 800x700) calculates optimal 2:1 table and matched controls height', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 700));

      late ResponsiveLayoutHelper layout;
      late OptimalTableMetrics metrics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                layout = ResponsiveLayoutHelper.of(context, constraints);
                metrics = layout.computeTableMetrics(
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight - 70, // minus top bar
                );
                return Container();
              },
            ),
          ),
        ),
      );

      // Z Fold unfolded has aspect ratio ~ 1.14 (square or foldable)
      expect(layout.isSquareOrFoldable, isTrue);
      expect(layout.isTablet, isTrue);
      // Upscale factor should be > 1.10 for comfortable large-screen gaming
      expect(layout.upscaleFactor, greaterThanOrEqualTo(1.10));

      // Table must strictly maintain 2:1 ratio
      expect(metrics.tableWidth, closeTo(metrics.tableHeight * 2.0, 0.01));
      // Station height must match table height exactly (controls do not stretch to infinity)
      expect(metrics.stationHeight, equals(metrics.tableHeight));
      // Station width must accommodate table + power control + aim control + paddings
      expect(metrics.stationWidth, lessThanOrEqualTo(800.0));
      expect(metrics.tableHeight, lessThanOrEqualTo(630.0));
    });

    testWidgets('Galaxy Z Fold Cover Screen (Ultra-Wide 23:9 / 920x340) scales compactly without overflowing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(920, 340));

      late ResponsiveLayoutHelper layout;
      late OptimalTableMetrics metrics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                layout = ResponsiveLayoutHelper.of(context, constraints);
                metrics = layout.computeTableMetrics(
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight - 50,
                );
                return Container();
              },
            ),
          ),
        ),
      );

      // 920 / 340 = 2.70 (Ultra-wide cover screen)
      expect(layout.isUltraWide, isTrue);
      expect(layout.isSquareOrFoldable, isFalse);

      // Table must strictly maintain 2:1 ratio
      expect(metrics.tableWidth, closeTo(metrics.tableHeight * 2.0, 0.01));
      expect(metrics.stationWidth, lessThanOrEqualTo(920.0));
      expect(metrics.stationHeight, lessThanOrEqualTo(290.0));
    });

    testWidgets('Surface Duo Spanned Dual Screen (2700x1800 or 1080x720) detects vertical hinge seam', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1114, 720));

      const hingeRect = Rect.fromLTRB(540, 0, 574, 720);
      const hingeFeature = DisplayFeature(
        bounds: hingeRect,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      late ResponsiveLayoutHelper layout;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1114, 720),
              displayFeatures: [hingeFeature],
            ),
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  layout = ResponsiveLayoutHelper.of(context, constraints);
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      expect(layout.hasHinge, isTrue);
      expect(layout.isVerticalHinge, isTrue);
      expect(layout.hingeBounds, equals(hingeRect));
    });

    testWidgets('Standard Mobile (800x380, 20:9) fills screen height and centers table station', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 380));

      late ResponsiveLayoutHelper layout;
      late OptimalTableMetrics metrics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                layout = ResponsiveLayoutHelper.of(context, constraints);
                metrics = layout.computeTableMetrics(
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight - 60,
                );
                return Container();
              },
            ),
          ),
        ),
      );

      expect(layout.isSquareOrFoldable, isFalse);
      expect(layout.upscaleFactor, closeTo(1.0, 0.05));
      expect(metrics.tableWidth, closeTo(metrics.tableHeight * 2.0, 0.01));
      expect(metrics.stationWidth, lessThanOrEqualTo(800.0));
    });

    testWidgets('Compact Phone (640x340) handles small dimensions without clipping', (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 340));

      late ResponsiveLayoutHelper layout;
      late OptimalTableMetrics metrics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                layout = ResponsiveLayoutHelper.of(context, constraints);
                metrics = layout.computeTableMetrics(
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight - 48,
                );
                return Container();
              },
            ),
          ),
        ),
      );

      expect(layout.isUltraCompact, isTrue);
      expect(layout.upscaleFactor, lessThan(1.0));
      expect(metrics.stationWidth, lessThanOrEqualTo(640.0));
    });
  });
  group('1vs1 Pass & Play Level 1 Cue Restriction Tests', () {
    test('1vs1 mode on the same machine strictly enforces Level 1 cue for both players', () {
      final game = BilliardGame();
      // Player 1 equipped cue upgraded to Level 10
      ProgressionService.instance.applyAdminPrivileges();
      expect(ProgressionService.instance.equippedCueLevel, equals(10));

      // Player 2 cue set to Level 4
      game.setPlayer2Cue('phoenix_flame', 4);

      // Start 1vs1 Pass & Play match
      game.startPlayerMatch();

      expect(game.isPassAndPlay, isTrue);

      // Turn 1 (Player 1): Must be strictly locked to Level 1
      game.currentTurn.value = 1;
      final (p1Cue, p1Level) = game.getActivePlayerCue();
      expect(p1Cue.id, equals('dragon_god'));
      expect(p1Level, equals(1));

      // Turn 2 (Player 2): Must be strictly locked to Level 1
      game.currentTurn.value = 2;
      final (p2Cue, p2Level) = game.getActivePlayerCue();
      expect(p2Cue.id, equals('phoenix_flame'));
      expect(p2Level, equals(1));
    });
  });
}
