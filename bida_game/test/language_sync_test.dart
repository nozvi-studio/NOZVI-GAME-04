import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/services/language_service.dart';
import 'package:bida_game/services/auth_service.dart';
import 'package:bida_game/models/medal_model.dart';
import 'package:bida_game/models/table_skin_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Synchronization & Localization Tests', () {
    test('Language switching dynamically updates Table Shop, Guest Name, and Medals', () {
      final langService = LanguageService.instance;
      final auth = AuthService.instance;

      // 1. Test VIETNAMESE (vi)
      langService.setLanguage(AppLanguage.vi);
      expect('table_shop'.tr.toUpperCase(), equals('BÀN ĐẤU'));
      expect('table_shop_title'.tr, equals('CỬA HÀNG BÀN BIDA'));
      expect(MedalCatalog.getById('english_spin_master')!.localizedName, equals('Thần Xoáy Áp-Phê'));
      expect(TableSkinCatalog.getById('classic_green').localizedName, equals('Bàn Nỉ Xanh Cổ Điển'));
      expect(auth.displayName, startsWith('Cơ Thủ Khách'));

      // 2. Test CHINESE (zh) - Matching user screenshots
      langService.setLanguage(AppLanguage.zh);
      expect('table_shop'.tr.toUpperCase(), equals('球桌'));
      expect('table_shop_title'.tr, equals('台球桌商城'));
      expect(MedalCatalog.getById('english_spin_master')!.localizedName, equals('旋转掌控大师'));
      expect(TableSkinCatalog.getById('classic_green').localizedName, equals('经典绿呢台面'));
      expect(auth.displayName, startsWith('游客选手'));

      // 3. Test ENGLISH (en)
      langService.setLanguage(AppLanguage.en);
      expect('table_shop'.tr.toUpperCase(), equals('TABLES'));
      expect('table_shop_title'.tr, equals('POOL TABLE SHOP'));
      expect(MedalCatalog.getById('english_spin_master')!.localizedName, equals('English Spin Master'));
      expect(TableSkinCatalog.getById('classic_green').localizedName, equals('Classic Green Felt'));
      expect(auth.displayName, startsWith('Guest Player'));

      // 4. Test JAPANESE (ja)
      langService.setLanguage(AppLanguage.ja);
      expect('table_shop'.tr.toUpperCase(), equals('テーブル'));
      expect(MedalCatalog.getById('english_spin_master')!.localizedName, equals('スピンマスター'));
      expect(auth.displayName, startsWith('ゲストプレイヤー'));

      // 5. Test KOREAN (ko)
      langService.setLanguage(AppLanguage.ko);
      expect('table_shop'.tr.toUpperCase(), equals('테이블'));
      expect(MedalCatalog.getById('english_spin_master')!.localizedName, equals('스핀의 제왕'));
      expect(auth.displayName, startsWith('게스트 플레이어'));

      // Revert to Vietnamese
      langService.setLanguage(AppLanguage.vi);
    });
  });
}
