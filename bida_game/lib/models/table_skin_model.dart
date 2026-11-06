import 'package:flutter/material.dart';
import '../services/language_service.dart';

/// Phẩm cấp Bàn Bida
enum TableRarity {
  standard,
  rare,
  epic,
  legendary,
  mythic,
}

extension TableRarityExt on TableRarity {
  String get label {
    return LanguageService.instance.localizeTableRarity(name, switch (this) {
      TableRarity.standard => 'Tiêu Chuẩn',
      TableRarity.rare => 'Hiếm',
      TableRarity.epic => 'Sử Thi',
      TableRarity.legendary => 'Huyền Thoại',
      TableRarity.mythic => 'Thần Thoại',
    });
  }

  Color get glowColor {
    switch (this) {
      case TableRarity.standard:
        return const Color(0xFF26A69A);
      case TableRarity.rare:
        return const Color(0xFF29B6F6);
      case TableRarity.epic:
        return const Color(0xFFAB47BC);
      case TableRarity.legendary:
        return const Color(0xFFFFB300);
      case TableRarity.mythic:
        return const Color(0xFFFF1744);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case TableRarity.standard:
        return [const Color(0xFF26A69A), const Color(0xFF00796B)];
      case TableRarity.rare:
        return [const Color(0xFF29B6F6), const Color(0xFF0288D1)];
      case TableRarity.epic:
        return [const Color(0xFFE040FB), const Color(0xFF7B1FA2)];
      case TableRarity.legendary:
        return [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
      case TableRarity.mythic:
        return [const Color(0xFFFF5252), const Color(0xFFD50000)];
    }
  }
}

/// Hệ Concept Anime đặc trưng của Bàn Đấu
enum TableAnimeConcept {
  classic('Cổ Điển', 'Classic', Icons.table_bar),
  sakuraZen('Hoa Anh Đào Kimetsu', 'Sakura Zen', Icons.spa),
  cyberTokyo('Cyberpunk Neo Tokyo', 'Cyber Neo Tokyo', Icons.memory),
  dragonLava('Long Thần Dung Nham', 'Dragon Magma', Icons.local_fire_department),
  arcaneGrimoire('Trận Đồ Ma Pháp', 'Arcane Grimoire', Icons.auto_awesome),
  shadowVoid('Vực Sâu Bóng Tối', 'Shadow Void', Icons.dark_mode),
  mechaEva('Pháo Đài Biomecha', 'Mecha Citadel', Icons.smart_toy);

  final String viLabel;
  final String enLabel;
  final IconData icon;
  const TableAnimeConcept(this.viLabel, this.enLabel, this.icon);

  String get localizedLabel {
    final code = LanguageService.instance.currentCode;
    switch (this) {
      case TableAnimeConcept.classic:
        return switch (code) {
          'zh' => '经典复古',
          'ja' => 'クラシック',
          'ko' => '클래식',
          'en' => 'Classic',
          _ => viLabel,
        };
      case TableAnimeConcept.sakuraZen:
        return switch (code) {
          'zh' => '樱花和风',
          'ja' => '桜の禅',
          'ko' => '사쿠라 젠',
          'en' => 'Sakura Zen',
          _ => viLabel,
        };
      case TableAnimeConcept.cyberTokyo:
        return switch (code) {
          'zh' => '赛博新东京',
          'ja' => 'サイバーネオ東京',
          'ko' => '사이버 네오 도쿄',
          'en' => 'Cyber Neo Tokyo',
          _ => viLabel,
        };
      case TableAnimeConcept.dragonLava:
        return switch (code) {
          'zh' => '龙神熔岩',
          'ja' => '竜神マグマ',
          'ko' => '용신 용암',
          'en' => 'Dragon Magma',
          _ => viLabel,
        };
      case TableAnimeConcept.arcaneGrimoire:
        return switch (code) {
          'zh' => '奥术魔导阵',
          'ja' => '秘術の魔導書',
          'ko' => '비전 마법진',
          'en' => 'Arcane Grimoire',
          _ => viLabel,
        };
      case TableAnimeConcept.shadowVoid:
        return switch (code) {
          'zh' => '暗影虚空',
          'ja' => 'シャドウヴォイド',
          'ko' => '그림자 공허',
          'en' => 'Shadow Void',
          _ => viLabel,
        };
      case TableAnimeConcept.mechaEva:
        return switch (code) {
          'zh' => '机甲要塞',
          'ja' => 'メカ要塞',
          'ko' => '메카 요새',
          'en' => 'Mecha Citadel',
          _ => viLabel,
        };
    }
  }
}

/// Đại diện cho một mẫu Skin Bàn Bida tùy chỉnh
class TableSkinModel {
  final String id;
  final String name;
  final String description;
  final Color clothPrimary;
  final Color clothSecondary;
  final Color railColor;
  final Color railAccentColor;
  final Color pocketColor;
  final Color cushionShadowColor;
  final TableRarity rarity;
  final int priceCoins;
  final int priceDiamonds;
  final int unlockLevel;
  final String pattern;
  final TableAnimeConcept animeConcept;

  const TableSkinModel({
    required this.id,
    required this.name,
    required this.description,
    required this.clothPrimary,
    required this.clothSecondary,
    required this.railColor,
    required this.railAccentColor,
    required this.pocketColor,
    this.cushionShadowColor = const Color(0x66000000),
    this.rarity = TableRarity.standard,
    this.priceCoins = 0,
    this.priceDiamonds = 0,
    this.unlockLevel = 1,
    this.pattern = 'classic',
    this.animeConcept = TableAnimeConcept.classic,
  });

  String get localizedName =>
      LanguageService.instance.localizeTableSkinName(id, name);

  String get localizedDescription =>
      LanguageService.instance.localizeTableSkinDescription(id, description);
}

/// Danh mục 20 Bàn Bida độc đáo đa dạng phong cách, phẩm cấp và màu sắc
class TableSkinCatalog {
  static const TableSkinModel classicGreen = TableSkinModel(
    id: 'classic_green',
    name: 'Bàn Nỉ Xanh Cổ Điển',
    description: 'Bàn nỉ xanh truyền thống chuẩn thi đấu quốc tế với viền gỗ mun trầm ấm.',
    clothPrimary: Color(0xFF11633F),
    clothSecondary: Color(0xFF093E25),
    railColor: Color(0xFF3E2723),
    railAccentColor: Color(0xFFFFD54F),
    pocketColor: Color(0xFF141414),
    cushionShadowColor: Color(0x77000000),
    rarity: TableRarity.standard,
    priceCoins: 0,
    priceDiamonds: 0,
    unlockLevel: 1,
    pattern: 'classic',
  );

  static const TableSkinModel royalNavy = TableSkinModel(
    id: 'royal_navy',
    name: 'Hải Quân Hoàng Gia',
    description: 'Vải nỉ xanh Navy hoàng gia sang trọng kết hợp thành băng gỗ gụ và điểm ngắm bạc.',
    clothPrimary: Color(0xFF153B66),
    clothSecondary: Color(0xFF0A223E),
    railColor: Color(0xFF241612),
    railAccentColor: Color(0xFFB0BEC5),
    pocketColor: Color(0xFF111E2E),
    cushionShadowColor: Color(0x88001122),
    rarity: TableRarity.standard,
    priceCoins: 2500,
    priceDiamonds: 0,
    unlockLevel: 2,
    pattern: 'classic',
  );

  static const TableSkinModel crimsonVelvet = TableSkinModel(
    id: 'crimson_velvet',
    name: 'Nhung Đỏ Quý Tộc',
    description: 'Nỉ nhung đỏ thắm cao cấp phong cách quý tộc châu Âu với giác cắt vàng kim rực rỡ.',
    clothPrimary: Color(0xFF800C1B),
    clothSecondary: Color(0xFF4E050E),
    railColor: Color(0xFF26120E),
    railAccentColor: Color(0xFFFFD700),
    pocketColor: Color(0xFF1F0D0C),
    cushionShadowColor: Color(0x882A0307),
    rarity: TableRarity.rare,
    priceCoins: 5000,
    priceDiamonds: 0,
    unlockLevel: 3,
    pattern: 'velvet',
  );

  static const TableSkinModel sandDune = TableSkinModel(
    id: 'sand_dune',
    name: 'Bão Cát Sa Mạc',
    description: 'Sắc vàng cát sa mạc ấm cúng cùng thành băng gỗ thông tuyết mộc mạc và đinh tán đồng.',
    clothPrimary: Color(0xFFC29B38),
    clothSecondary: Color(0xFF7D601D),
    railColor: Color(0xFF4E3629),
    railAccentColor: Color(0xFFFFE082),
    pocketColor: Color(0xFF2E1F18),
    cushionShadowColor: Color(0x66332211),
    rarity: TableRarity.standard,
    priceCoins: 6000,
    priceDiamonds: 0,
    unlockLevel: 3,
    pattern: 'sand',
  );

  static const TableSkinModel emeraldMaster = TableSkinModel(
    id: 'emerald_master',
    name: 'Ngọc Lục Bảo Đại Sư',
    description: 'Màu xanh lục bảo lấp lánh phản chiếu hào quang của các bậc thầy bi-a thế giới.',
    clothPrimary: Color(0xFF00796B),
    clothSecondary: Color(0xFF004D40),
    railColor: Color(0xFF1B2421),
    railAccentColor: Color(0xFF80CBC4),
    pocketColor: Color(0xFF0E1A17),
    cushionShadowColor: Color(0x77002822),
    rarity: TableRarity.rare,
    priceCoins: 8000,
    priceDiamonds: 0,
    unlockLevel: 4,
    pattern: 'emerald',
  );

  static const TableSkinModel midnightShadow = TableSkinModel(
    id: 'midnight_shadow',
    name: 'Bóng Đêm Huyền Bí',
    description: 'Tông màu xám than chì huyền ảo với viền carbon đen mờ và điểm ngắm xanh cyan.',
    clothPrimary: Color(0xFF263238),
    clothSecondary: Color(0xFF10171A),
    railColor: Color(0xFF161C20),
    railAccentColor: Color(0xFF00E5FF),
    pocketColor: Color(0xFF0B0E10),
    cushionShadowColor: Color(0x99000000),
    rarity: TableRarity.rare,
    priceCoins: 12000,
    priceDiamonds: 0,
    unlockLevel: 5,
    pattern: 'shadow',
  );

  static const TableSkinModel sakuraBlossom = TableSkinModel(
    id: 'sakura_blossom',
    name: 'Hoa Anh Đào Kimetsu',
    description: 'Sắc hồng cánh hoa anh đào kiếm đạo Nhật Bản kết hợp biểu tượng gia huy Kamon và cánh hoa bay.',
    clothPrimary: Color(0xFFC25975),
    clothSecondary: Color(0xFF7A2A3E),
    railColor: Color(0xFF4A2830),
    railAccentColor: Color(0xFFFF80AB),
    pocketColor: Color(0xFF2A141A),
    cushionShadowColor: Color(0x6633111E),
    rarity: TableRarity.rare,
    priceCoins: 15000,
    priceDiamonds: 0,
    unlockLevel: 5,
    pattern: 'sakura',
    animeConcept: TableAnimeConcept.sakuraZen,
  );

  static const TableSkinModel copperVintage = TableSkinModel(
    id: 'copper_vintage',
    name: 'Đồng Đỏ Cổ Điển',
    description: 'Vải nỉ màu đồng đỏ cổ kính đậm chất hoài niệm với góc bàn ốp đồng tán đinh thủ công.',
    clothPrimary: Color(0xFF8D5B4C),
    clothSecondary: Color(0xFF4E2C22),
    railColor: Color(0xFF3A1F18),
    railAccentColor: Color(0xFFFFAB91),
    pocketColor: Color(0xFF26120C),
    cushionShadowColor: Color(0x77281008),
    rarity: TableRarity.rare,
    priceCoins: 18000,
    priceDiamonds: 0,
    unlockLevel: 6,
    pattern: 'vintage',
  );

  static const TableSkinModel cyberNeon = TableSkinModel(
    id: 'cyber_neon',
    name: 'Cyberpunk Neo Tokyo 2077',
    description: 'Lưới ma trận vi mạch số phát quang neon cyan-magenta với ký hiệu điện não và băng từ trường.',
    clothPrimary: Color(0xFF0D1B2A),
    clothSecondary: Color(0xFF050B14),
    railColor: Color(0xFF0F151F),
    railAccentColor: Color(0xFF00F0FF),
    pocketColor: Color(0xFF1F1B24),
    cushionShadowColor: Color(0xAA00F0FF),
    rarity: TableRarity.epic,
    priceCoins: 20000,
    priceDiamonds: 30,
    unlockLevel: 6,
    pattern: 'cyber',
    animeConcept: TableAnimeConcept.cyberTokyo,
  );

  static const TableSkinModel volcanicMagma = TableSkinModel(
    id: 'volcanic_magma',
    name: 'Dung Nham Long Thần',
    description: 'Trận đồ rồng lửa dung nham bốc khói cùng các vết nứt nham thạch nóng bỏng và vảy rồng bảo hộ.',
    clothPrimary: Color(0xFF9E2A2B),
    clothSecondary: Color(0xFF540B0E),
    railColor: Color(0xFF2B090A),
    railAccentColor: Color(0xFFFF6B35),
    pocketColor: Color(0xFF1A0506),
    cushionShadowColor: Color(0x99FF3D00),
    rarity: TableRarity.epic,
    priceCoins: 25000,
    priceDiamonds: 40,
    unlockLevel: 7,
    pattern: 'magma',
    animeConcept: TableAnimeConcept.dragonLava,
  );

  static const TableSkinModel amethystGalaxy = TableSkinModel(
    id: 'amethyst_galaxy',
    name: 'Trận Đồ Ma Pháp Tinh Tú',
    description: 'Vòng tròn ma pháp thuật cổ đại phát quang trên nền nỉ tinh vân tím vũ trụ và chòm sao đa chiều.',
    clothPrimary: Color(0xFF4A148C),
    clothSecondary: Color(0xFF240046),
    railColor: Color(0xFF1C0830),
    railAccentColor: Color(0xFFE040FB),
    pocketColor: Color(0xFF110320),
    cushionShadowColor: Color(0x883C096C),
    rarity: TableRarity.epic,
    priceCoins: 30000,
    priceDiamonds: 50,
    unlockLevel: 8,
    pattern: 'galaxy',
    animeConcept: TableAnimeConcept.arcaneGrimoire,
  );

  static const TableSkinModel electricViolet = TableSkinModel(
    id: 'electric_violet',
    name: 'Tia Sét Tím Cyberpunk',
    description: 'Năng lượng điện trường tím sẫm chớp nhoáng với thành bàn mạ crom phản chiếu sắc sảo.',
    clothPrimary: Color(0xFF311B92),
    clothSecondary: Color(0xFF1A0A5E),
    railColor: Color(0xFF150A40),
    railAccentColor: Color(0xFF7C4DFF),
    pocketColor: Color(0xFF0D0528),
    cushionShadowColor: Color(0x88651FFF),
    rarity: TableRarity.epic,
    priceCoins: 38000,
    priceDiamonds: 60,
    unlockLevel: 8,
    pattern: 'electric',
    animeConcept: TableAnimeConcept.cyberTokyo,
  );

  static const TableSkinModel carbonStealth = TableSkinModel(
    id: 'carbon_stealth',
    name: 'Pháo Đài Biomecha EVA',
    description: 'Khung giáp tổ ong lục giác AT-Field của chiến cơ Mecha tương lai với vạch chỉ dẫn quân sự.',
    clothPrimary: Color(0xFF1F2421),
    clothSecondary: Color(0xFF111412),
    railColor: Color(0xFF151816),
    railAccentColor: Color(0xFF76FF03),
    pocketColor: Color(0xFF0C0E0D),
    cushionShadowColor: Color(0xAA000000),
    rarity: TableRarity.epic,
    priceCoins: 40000,
    priceDiamonds: 60,
    unlockLevel: 8,
    pattern: 'carbon',
    animeConcept: TableAnimeConcept.mechaEva,
  );

  static const TableSkinModel iceGlacier = TableSkinModel(
    id: 'ice_glacier',
    name: 'Băng Giá Bắc Cực',
    description: 'Mặt bàn trắng ngọc băng giá như hồ nước đóng băng ngàn năm tại cực bắc địa cầu.',
    clothPrimary: Color(0xFF1A5276),
    clothSecondary: Color(0xFF0B2536),
    railColor: Color(0xFF193142),
    railAccentColor: Color(0xFF80DEEA),
    pocketColor: Color(0xFF0A1822),
    cushionShadowColor: Color(0x7700B0FF),
    rarity: TableRarity.epic,
    priceCoins: 35000,
    priceDiamonds: 50,
    unlockLevel: 9,
    pattern: 'glacier',
    animeConcept: TableAnimeConcept.arcaneGrimoire,
  );

  static const TableSkinModel rubyRoyale = TableSkinModel(
    id: 'ruby_royale',
    name: 'Hồng Ngọc Hoàng Tộc',
    description: 'Sắc đỏ hồng ngọc lấp lánh như vương miện hoàng gia với thành bàn gỗ trắc chạm khảm.',
    clothPrimary: Color(0xFF880E4F),
    clothSecondary: Color(0xFF4A0026),
    railColor: Color(0xFF2E0518),
    railAccentColor: Color(0xFFFF4081),
    pocketColor: Color(0xFF1C020E),
    cushionShadowColor: Color(0x88C2185B),
    rarity: TableRarity.epic,
    priceCoins: 45000,
    priceDiamonds: 70,
    unlockLevel: 9,
    pattern: 'ruby',
  );

  static const TableSkinModel goldenLuxury = TableSkinModel(
    id: 'golden_luxury',
    name: 'Hoàng Kim Vạn Lượng',
    description: 'Vải nỉ dệt ánh kim champagne lộng lẫy và thành băng dát vàng 24K quyền lực tối thượng.',
    clothPrimary: Color(0xFF8A6D1C),
    clothSecondary: Color(0xFF503D0B),
    railColor: Color(0xFF332505),
    railAccentColor: Color(0xFFFFD700),
    pocketColor: Color(0xFF201703),
    cushionShadowColor: Color(0x99FFD700),
    rarity: TableRarity.epic,
    priceCoins: 50000,
    priceDiamonds: 80,
    unlockLevel: 10,
    pattern: 'luxury',
  );

  static const TableSkinModel jadeDynasty = TableSkinModel(
    id: 'jade_dynasty',
    name: 'Hoàng Triều Ngọc Bích',
    description: 'Ngọc bích hoàng gia thuần khiết kết hợp thành băng gỗ tử đàn khảm rồng vàng quyền quý.',
    clothPrimary: Color(0xFF005A36),
    clothSecondary: Color(0xFF00331E),
    railColor: Color(0xFF3E1210),
    railAccentColor: Color(0xFF69F0AE),
    pocketColor: Color(0xFF1A0504),
    cushionShadowColor: Color(0x88004D40),
    rarity: TableRarity.legendary,
    priceCoins: 80000,
    priceDiamonds: 120,
    unlockLevel: 12,
    pattern: 'jade',
  );

  static const TableSkinModel phantomBlack = TableSkinModel(
    id: 'phantom_black',
    name: 'Bóng Ma Hư Vô Solo',
    description: 'Lãnh địa hắc ám của Quân vương Bóng tối với vòng xoáy hư vô tím sẫm ma mị và cổ ngữ hắc ám.',
    clothPrimary: Color(0xFF121212),
    clothSecondary: Color(0xFF080808),
    railColor: Color(0xFF0A0A0A),
    railAccentColor: Color(0xFFB388FF),
    pocketColor: Color(0xFF050505),
    cushionShadowColor: Color(0xBB7C4DFF),
    rarity: TableRarity.legendary,
    priceCoins: 100000,
    priceDiamonds: 150,
    unlockLevel: 14,
    pattern: 'void',
    animeConcept: TableAnimeConcept.shadowVoid,
  );

  static const TableSkinModel dragonEmperor = TableSkinModel(
    id: 'dragon_emperor',
    name: 'Long Hoàng Bá Chủ',
    description: 'Trận đồ rồng uy nghiêm với đại phong ấn thần long trên nền lụa đỏ thẫm cuộn lửa bảo hộ.',
    clothPrimary: Color(0xFF700B0B),
    clothSecondary: Color(0xFF380000),
    railColor: Color(0xFF1F0000),
    railAccentColor: Color(0xFFFFB300),
    pocketColor: Color(0xFF140000),
    cushionShadowColor: Color(0xAAFF8F00),
    rarity: TableRarity.mythic,
    priceCoins: 180000,
    priceDiamonds: 250,
    unlockLevel: 16,
    pattern: 'dragon',
    animeConcept: TableAnimeConcept.dragonLava,
  );

  static const TableSkinModel celestialOlympus = TableSkinModel(
    id: 'celestial_olympus',
    name: 'Đỉnh Cao Olympus',
    description: 'Đá cẩm thạch trắng Olympus của các vị thần kết hợp nỉ xanh thiên đường và hoa văn thần thánh.',
    clothPrimary: Color(0xFF283593),
    clothSecondary: Color(0xFF101957),
    railColor: Color(0xFFD6DBDF),
    railAccentColor: Color(0xFFFFD700),
    pocketColor: Color(0xFF1A237E),
    cushionShadowColor: Color(0x88FFD700),
    rarity: TableRarity.mythic,
    priceCoins: 250000,
    priceDiamonds: 300,
    unlockLevel: 20,
    pattern: 'olympus',
  );

  static const List<TableSkinModel> allTables = [
    classicGreen,
    royalNavy,
    crimsonVelvet,
    sandDune,
    emeraldMaster,
    midnightShadow,
    sakuraBlossom,
    copperVintage,
    cyberNeon,
    volcanicMagma,
    amethystGalaxy,
    electricViolet,
    carbonStealth,
    iceGlacier,
    rubyRoyale,
    goldenLuxury,
    jadeDynasty,
    phantomBlack,
    dragonEmperor,
    celestialOlympus,
  ];

  static TableSkinModel getById(String id) {
    return allTables.firstWhere(
      (t) => t.id == id,
      orElse: () => classicGreen,
    );
  }
}
