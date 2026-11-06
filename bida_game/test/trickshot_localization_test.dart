import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/models/legendary_trickshot_model.dart';
import 'package:bida_game/services/trickshot_localization.dart';

void main() {
  group('112 Legendary Trickshots Full Localization Tests (Titles, Descriptions, Hints)', () {
    final catalog = LegendaryTrickshotCatalog.trickshots;

    test('Catalog contains exactly 112 trickshots across 14 masters', () {
      expect(catalog.length, equals(112));
    });

    for (final lang in ['en', 'zh', 'ja', 'ko']) {
      test('All 112 trickshots translate TITLES successfully to $lang without returning raw Vietnamese title', () {
        int count = 0;
        for (final shot in catalog) {
          final translated = TrickshotLocalization.getTitle(shot.id, lang, shot.title);
          expect(translated, isNotEmpty);
          expect(translated, isNot(equals(shot.title)),
              reason: 'Shot ${shot.id} title failed to translate in $lang');
          count++;
        }
        expect(count, equals(112));
      });

      test('All 112 trickshots translate DESCRIPTIONS successfully to $lang without returning raw Vietnamese description', () {
        int count = 0;
        for (final shot in catalog) {
          final translated = TrickshotLocalization.getDescription(shot.id, lang, shot.description);
          expect(translated, isNotEmpty);
          expect(translated, isNot(equals(shot.description)),
              reason: 'Shot ${shot.id} description failed to translate in $lang');
          expect(translated, isNot(contains('Master trickshot by')),
              reason: 'Shot ${shot.id} description fell back to generic template in $lang');
          count++;
        }
        expect(count, equals(112));
      });

      test('All trickshots with custom HINTS translate successfully to $lang without returning raw Vietnamese hint', () {
        int count = 0;
        for (final shot in catalog) {
          if (shot.techniqueHint.trim().isEmpty) continue;
          final translated = TrickshotLocalization.getHint(shot.id, lang, shot.techniqueHint);
          expect(translated, isNotEmpty);
          expect(translated, isNot(equals(shot.techniqueHint)),
              reason: 'Shot ${shot.id} hint failed to translate in $lang');
          count++;
        }
        expect(count, equals(112));
      });
    }

    test('All 112 trickshots return original title and description in Vietnamese (vi)', () {
      for (final shot in catalog) {
        expect(TrickshotLocalization.getTitle(shot.id, 'vi', shot.title), equals(shot.title));
        expect(TrickshotLocalization.getDescription(shot.id, 'vi', shot.description), equals(shot.description));
        if (shot.techniqueHint.isNotEmpty) {
          expect(TrickshotLocalization.getHint(shot.id, 'vi', shot.techniqueHint), equals(shot.techniqueHint));
        }
      }
    });

    test('Master names translate properly across all 5 languages', () {
      final shot = catalog.first; // Efren
      expect(TrickshotLocalization.getMasterName(shot.masterName, 'vi'), contains('Efren'));
      expect(TrickshotLocalization.getMasterName(shot.masterName, 'en'), contains('Efren'));
      expect(TrickshotLocalization.getMasterName(shot.masterName, 'zh'), contains('雷耶斯'));
      expect(TrickshotLocalization.getMasterName(shot.masterName, 'ja'), contains('エフレン'));
      expect(TrickshotLocalization.getMasterName(shot.masterName, 'ko'), contains('레예스'));
    });

    test('Master nicknames translate properly across all languages', () {
      final shot = catalog.first;
      expect(TrickshotLocalization.getNickname(shot.id, 'en', shot.masterNickname), equals('The Magician'));
      expect(TrickshotLocalization.getNickname(shot.id, 'zh', shot.masterNickname), contains('魔术师'));
      expect(TrickshotLocalization.getNickname(shot.id, 'ja', shot.masterNickname), contains('魔術師'));
      expect(TrickshotLocalization.getNickname(shot.id, 'ko', shot.masterNickname), contains('마술사'));
    });

    test('Reverse lookup by Vietnamese title and description works seamlessly as secondary fallback', () {
      for (final shot in catalog) {
        final fallbackEn = TrickshotLocalization.getTitle('unknown_custom_id', 'en', shot.title);
        expect(fallbackEn, isNot(equals(shot.title)));

        final fallbackDescEn = TrickshotLocalization.getDescription('unknown_custom_id', 'en', shot.description);
        expect(fallbackDescEn, isNot(equals(shot.description)));
      }
    });
  });
}
