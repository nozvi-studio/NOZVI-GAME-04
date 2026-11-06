import 'package:flutter/material.dart';
import '../services/language_service.dart';

enum CueRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Hệ Concept Anime đặc trưng của cây cơ
enum CueAnimeConcept {
  classic('Cổ Điển', 'Classic', Icons.sports),
  katanaSamurai('Kiếm Sĩ Nichirin', 'Nichirin Samurai', Icons.flash_on),
  cyberNeo('Cyberpunk Neo', 'Cyberpunk Neo', Icons.memory),
  dragonFlame('Hỏa Long Shonen', 'Dragon Flame', Icons.local_fire_department),
  arcaneMagic('Ma Pháp Tinh Tú', 'Arcane Astral', Icons.auto_awesome),
  shadowVoid('Quân Vương Bóng Tối', 'Shadow Monarch', Icons.dark_mode),
  mechaGundam('Biomecha EVA', 'Biomecha Core', Icons.smart_toy),
  sakuraZen('Hoa Anh Đào', 'Sakura Spirit', Icons.spa),
  frostCryo('Băng Phong Bắc Cực', 'Cryo Frost', Icons.ac_unit);

  final String viLabel;
  final String enLabel;
  final IconData icon;
  const CueAnimeConcept(this.viLabel, this.enLabel, this.icon);

  String get localizedLabel {
    final code = LanguageService.instance.currentCode;
    switch (this) {
      case CueAnimeConcept.classic:
        return switch (code) {
          'zh' => '经典复古',
          'ja' => 'クラシック',
          'ko' => '클래식',
          'en' => 'Classic',
          _ => viLabel,
        };
      case CueAnimeConcept.katanaSamurai:
        return switch (code) {
          'zh' => '日轮武士',
          'ja' => '日輪侍',
          'ko' => '일륜 사무라이',
          'en' => 'Nichirin Samurai',
          _ => viLabel,
        };
      case CueAnimeConcept.cyberNeo:
        return switch (code) {
          'zh' => '赛博霓虹',
          'ja' => 'サイバーネオ',
          'ko' => '사이버 네오',
          'en' => 'Cyberpunk Neo',
          _ => viLabel,
        };
      case CueAnimeConcept.dragonFlame:
        return switch (code) {
          'zh' => '炎龙少年',
          'ja' => '炎竜',
          'ko' => '화룡 소년',
          'en' => 'Dragon Flame',
          _ => viLabel,
        };
      case CueAnimeConcept.arcaneMagic:
        return switch (code) {
          'zh' => '秘术魔法',
          'ja' => '秘術魔法',
          'ko' => '아케인 마법',
          'en' => 'Arcane Magic',
          _ => viLabel,
        };
      case CueAnimeConcept.sakuraZen:
        return switch (code) {
          'zh' => '樱花之魂',
          'ja' => '桜の精神',
          'ko' => '사쿠라 스피릿',
          'en' => 'Sakura Spirit',
          _ => viLabel,
        };
      case CueAnimeConcept.shadowVoid:
        return switch (code) {
          'zh' => '暗影君王',
          'ja' => '影の君主',
          'ko' => '그림자 군주',
          'en' => 'Shadow Monarch',
          _ => viLabel,
        };
      case CueAnimeConcept.mechaGundam:
        return switch (code) {
          'zh' => '机甲核心',
          'ja' => '生体メカ',
          'ko' => '바이오메카',
          'en' => 'Biomecha Core',
          _ => viLabel,
        };
      case CueAnimeConcept.frostCryo:
        return switch (code) {
          'zh' => '北极霜冻',
          'ja' => '極寒フロスト',
          'ko' => '극지 프로스트',
          'en' => 'Cryo Frost',
          _ => viLabel,
        };
    }
  }
}

extension CueRarityExt on CueRarity {
  String get displayName {
    return LanguageService.instance.localizeCueRarity(name, switch (this) {
      CueRarity.common => 'Thường',
      CueRarity.rare => 'Hiếm',
      CueRarity.epic => 'Sử Thi',
      CueRarity.legendary => 'Huyền Thoại',
    });
  }


  Color get color {
    switch (this) {
      case CueRarity.common:
        return const Color(0xFF9E9E9E);
      case CueRarity.rare:
        return const Color(0xFF29B6F6);
      case CueRarity.epic:
        return const Color(0xFFAB47BC);
      case CueRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  Color get glowColor {
    switch (this) {
      case CueRarity.common:
        return Colors.white24;
      case CueRarity.rare:
        return const Color(0x6629B6F6);
      case CueRarity.epic:
        return const Color(0x88AB47BC);
      case CueRarity.legendary:
        return const Color(0xAAFFB300);
    }
  }
}

class CueStats {
  final double force; // 1.0 - 15.0
  final double aim;   // 1.0 - 15.0
  final double spin;  // 1.0 - 15.0
  final double time;  // 1.0 - 15.0

  const CueStats({
    required this.force,
    required this.aim,
    required this.spin,
    required this.time,
  });
}

class CueModel {
  final String id;
  final String name;
  final CueRarity rarity;
  final int requiredLevel;
  final int? priceCoins;
  final int? priceDiamonds;
  final String description;
  final String passivePerk;
  final CueStats baseStats;

  // Thuộc tính hình ảnh vector & vệt sáng
  final List<Color> shaftColors;
  final List<Color> handleColors;
  final Color tipColor;
  final Color auraColor;
  final Color ballTrailColor;
  final CueAnimeConcept animeConcept;

  const CueModel({
    required this.id,
    required this.name,
    required this.rarity,
    required this.requiredLevel,
    this.priceCoins,
    this.priceDiamonds,
    required this.description,
    required this.passivePerk,
    required this.baseStats,
    required this.shaftColors,
    required this.handleColors,
    required this.tipColor,
    required this.auraColor,
    required this.ballTrailColor,
    this.animeConcept = CueAnimeConcept.classic,
  });

  bool get isFree => priceCoins == null && priceDiamonds == null;

  String get localizedName => LanguageService.instance.localizeCueName(id, name);
  String get localizedDescription => LanguageService.instance.localizeCueDescription(id, description);
  String get localizedPerk => LanguageService.instance.localizeCuePerk(id, passivePerk);


  /// Tính toán 4 chỉ số theo cấp độ gậy (từ Lv.1 đến Lv.10)
  CueStats getStatsForLevel(int level) {
    final lvl = level.clamp(1, 10);
    final incrementFactor = (lvl - 1);

    // Mỗi cấp tăng tiến tỉ lệ thuận với độ hiếm của gậy
    final step = rarity == CueRarity.legendary
        ? 0.55
        : (rarity == CueRarity.epic
            ? 0.45
            : (rarity == CueRarity.rare ? 0.35 : 0.25));

    return CueStats(
      force: (baseStats.force + incrementFactor * step).clamp(1.0, 16.0),
      aim: (baseStats.aim + incrementFactor * step).clamp(1.0, 16.0),
      spin: (baseStats.spin + incrementFactor * step).clamp(1.0, 16.0),
      time: (baseStats.time + incrementFactor * step).clamp(1.0, 16.0),
    );
  }

  /// Chi phí Vàng để nâng cấp từ level hiện tại lên level tiếp theo
  int getUpgradeCostCoins(int currentLevel) {
    if (currentLevel >= 10) return 0;
    final baseCost = rarity == CueRarity.legendary
        ? 5000
        : (rarity == CueRarity.epic
            ? 3000
            : (rarity == CueRarity.rare ? 1500 : 800));
    return baseCost * currentLevel;
  }

  /// Hệ số gia tăng tốc độ bắn tối đa (Force multiplier)
  double getForceMultiplier(int level) {
    final stats = getStatsForLevel(level);
    // Chuẩn: 1.0 (ở force = 2.0) -> tối đa ~ 1.35 (ở force = 15.0)
    return 1.0 + (stats.force - 2.0) * 0.024;
  }

  /// Hệ số gia tăng độ dài tia ngắm (Aim multiplier)
  double getAimMultiplier(int level) {
    final stats = getStatsForLevel(level);
    // Chuẩn: 1.0 (ở aim = 2.0) -> tối đa ~ 1.6 (ở aim = 15.0)
    return 1.0 + (stats.aim - 2.0) * 0.042;
  }

  /// Hệ số độ nhạy áp-phê và trô bóng (Spin multiplier)
  double getSpinMultiplier(int level) {
    final stats = getStatsForLevel(level);
    // Chuẩn: 1.0 (ở spin = 1.0) -> tối đa ~ 1.55 (ở spin = 15.0)
    return 1.0 + (stats.spin - 1.0) * 0.038;
  }

  /// Thêm thời gian suy nghĩ mỗi lượt đánh (tính bằng giây)
  double getBonusTurnTimeSeconds(int level) {
    final stats = getStatsForLevel(level);
    return (stats.time - 1.0) * 0.5; // từ 0s đến ~7s
  }
}

class CueCatalog {
  static const CueModel standardCue = CueModel(
    id: 'standard_cue',
    name: 'Gậy Gỗ Tân Thủ',
    rarity: CueRarity.common,
    requiredLevel: 1,
    description: 'Cây gậy khởi đầu bằng gỗ phong tự nhiên, đầm tay và dễ làm quen.',
    passivePerk: 'Cân bằng cơ bản, không có nội tại phụ.',
    baseStats: CueStats(force: 2.5, aim: 2.5, spin: 2.0, time: 2.0),
    shaftColors: [Color(0xFFE2C498), Color(0xFFC89D66), Color(0xFF9F6E3B)],
    handleColors: [Color(0xFF3E2723), Color(0xFF1B0000), Color(0xFF4E342E)],
    tipColor: Color(0xFF5D4037),
    auraColor: Color(0x33FFFFFF),
    ballTrailColor: Color(0x44FFFFFF),
    animeConcept: CueAnimeConcept.classic,
  );

  static const CueModel titanStriker = CueModel(
    id: 'titan_striker',
    name: 'Cơ Titan Thép',
    rarity: CueRarity.common,
    requiredLevel: 5,
    priceCoins: 3000,
    description: 'Lõi kim loại đúc nguyên khối chịu lực cao, gia cố đầu ngọn siêu cứng.',
    passivePerk: 'Heavy Break: Tăng thêm 15% xung lực khi đánh vỡ cụm bi khai cuộc.',
    baseStats: CueStats(force: 4.5, aim: 3.5, spin: 2.5, time: 2.5),
    shaftColors: [Color(0xFFCFD8DC), Color(0xFF90A4AE), Color(0xFF607D8B)],
    handleColors: [Color(0xFF263238), Color(0xFF37474F), Color(0xFF212121)],
    tipColor: Color(0xFF78909C),
    auraColor: Color(0x6690A4AE),
    ballTrailColor: Color(0x88CFD8DC),
    animeConcept: CueAnimeConcept.mechaGundam,
  );

  static const CueModel frostbite = CueModel(
    id: 'frostbite',
    name: 'Cơ Băng Phong',
    rarity: CueRarity.rare,
    requiredLevel: 12,
    priceCoins: 18000,
    description: 'Chế tác từ tinh thể băng vĩnh cửu Bắc Cực, tỏa ra hàn khí xanh lạnh ngắt.',
    passivePerk: 'Ice Aim: Tia ngắm cực kỳ ổn định, làm chậm nhịp rung khi căn lực.',
    baseStats: CueStats(force: 5.5, aim: 5.5, spin: 4.5, time: 3.5),
    shaftColors: [Color(0xFFB3E5FC), Color(0xFF4FC3F7), Color(0xFF0288D1)],
    handleColors: [Color(0xFF01579B), Color(0xFF0D47A1), Color(0xFF002171)],
    tipColor: Color(0xFFE1F5FE),
    auraColor: Color(0x8803A9F4),
    ballTrailColor: Color(0xAA81D4FA),
    animeConcept: CueAnimeConcept.frostCryo,
  );

  static const CueModel goldenBull = CueModel(
    id: 'golden_bull',
    name: 'Cơ Kim Ngưu',
    rarity: CueRarity.rare,
    requiredLevel: 22,
    priceCoins: 50000,
    description: 'Dát vàng 24K nguyên chất chạm khắc biểu tượng cung hoàng đạo Kim Ngưu.',
    passivePerk: 'Jackpot Touch: Nhận thêm 10% Vàng thưởng sau mỗi trận thắng.',
    baseStats: CueStats(force: 6.5, aim: 5.5, spin: 5.5, time: 4.5),
    shaftColors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFFB300)],
    handleColors: [Color(0xFFFF8F00), Color(0xFF4E342E), Color(0xFFBF360C)],
    tipColor: Color(0xFFFFE082),
    auraColor: Color(0x99FFC107),
    ballTrailColor: Color(0xAAFFD54F),
    animeConcept: CueAnimeConcept.dragonFlame,
  );

  static const CueModel cyberNeo = CueModel(
    id: 'cyber_neo',
    name: 'Cơ Cyberpunk Neo',
    rarity: CueRarity.epic,
    requiredLevel: 35,
    priceCoins: 150000,
    description: 'Công nghệ tương lai năm 2077 với vi mạch bán dẫn và đèn LED tím neon.',
    passivePerk: 'Laser Line: Kéo dài tia ngắm thêm 20% và hiển thị đường rẽ bi rực sáng.',
    baseStats: CueStats(force: 7.5, aim: 7.5, spin: 6.5, time: 5.5),
    shaftColors: [Color(0xFFE1BEE7), Color(0xFFAB47BC), Color(0xFF7B1FA2)],
    handleColors: [Color(0xFF00E5FF), Color(0xFF1A237E), Color(0xFFD500F9)],
    tipColor: Color(0xFF00E5FF),
    auraColor: Color(0xAAAB47BC),
    ballTrailColor: Color(0xCCD500F9),
    animeConcept: CueAnimeConcept.cyberNeo,
  );

  static const CueModel phoenixFlame = CueModel(
    id: 'phoenix_flame',
    name: 'Cơ Hỏa Phụng',
    rarity: CueRarity.epic,
    requiredLevel: 48,
    priceDiamonds: 450,
    description: 'Được rèn từ tro tàn của Phượng Hoàng Lửa, thân gậy bốc cháy ngọn lửa bất tử.',
    passivePerk: 'Inferno Spin: Tăng vọt 25% độ giật trô bóng lùi và cu-lê tiến tới.',
    baseStats: CueStats(force: 8.5, aim: 8.5, spin: 8.5, time: 6.5),
    shaftColors: [Color(0xFFFFCCBC), Color(0xFFFF7043), Color(0xFFD84315)],
    handleColors: [Color(0xFFBF360C), Color(0xFFFF1744), Color(0xFF3E2723)],
    tipColor: Color(0xFFFFEB3B),
    auraColor: Color(0xBBFF5722),
    ballTrailColor: Color(0xDDFF3D00),
    animeConcept: CueAnimeConcept.dragonFlame,
  );

  static const CueModel dragonGod = CueModel(
    id: 'dragon_god',
    name: 'Cơ Đế Vương Rồng Vàng',
    rarity: CueRarity.legendary,
    requiredLevel: 60,
    priceDiamonds: 1500,
    description: 'Báu vật hoàng gia ngàn năm tuổi, mang sức mạnh thần long chấn động thiên địa.',
    passivePerk: 'Dragon Heart: Hoàn lại 50% tiền cược nếu thua ván; Vệt lửa rồng hộ mệnh.',
    baseStats: CueStats(force: 10.0, aim: 10.0, spin: 9.5, time: 8.0),
    shaftColors: [Color(0xFFFFF8E1), Color(0xFFFFE082), Color(0xFFFFC107)],
    handleColors: [Color(0xFFD50000), Color(0xFFFF6D00), Color(0xFFFFD600)],
    tipColor: Color(0xFFFFFFFF),
    auraColor: Color(0xCCFFD700),
    ballTrailColor: Color(0xFFFFD700),
    animeConcept: CueAnimeConcept.dragonFlame,
  );

  // --- CÁC MẪU CƠ CONCEPT ANIME ĐỘC ĐÁO MỚI ---

  static const CueModel nichirinKatana = CueModel(
    id: 'nichirin_katana',
    name: 'Hơi Thở Mặt Trời - Nichirin',
    rarity: CueRarity.legendary,
    requiredLevel: 15,
    priceCoins: 65000,
    description: 'Tuyệt kỹ kiếm thuật diệt quỷ, thân cơ hóa kiếm hắc kim với đường sống kiếm rực lửa và vành Tsuba hộ kiếm.',
    passivePerk: 'Sun Slash: Đường cơ sắc bén xé gió, tăng 22% xung lực cắt góc bi.',
    baseStats: CueStats(force: 8.5, aim: 9.0, spin: 8.5, time: 7.0),
    shaftColors: [Color(0xFF1E1E1E), Color(0xFFD50000), Color(0xFF111111)],
    handleColors: [Color(0xFF263238), Color(0xFFFFD54F), Color(0xFF1B0000)],
    tipColor: Color(0xFFFF1744),
    auraColor: Color(0xEEFF1744),
    ballTrailColor: Color(0xFFFF5252),
    animeConcept: CueAnimeConcept.katanaSamurai,
  );

  static const CueModel cyberRebellion = CueModel(
    id: 'cyber_rebellion',
    name: 'Pháo Năng Lượng Cyber Mecha',
    rarity: CueRarity.epic,
    requiredLevel: 18,
    priceCoins: 55000,
    description: 'Súng trường xung điện Neo Tokyo tích hợp vi mạch bán dẫn và bộ tản nhiệt plasma xanh neon.',
    passivePerk: 'Overclock Pulse: Phóng điện định hướng, tia ngắm ổn định tuyệt đối.',
    baseStats: CueStats(force: 7.8, aim: 8.8, spin: 7.0, time: 6.5),
    shaftColors: [Color(0xFF00E5FF), Color(0xFF18FFFF), Color(0xFF00B0FF)],
    handleColors: [Color(0xFF212121), Color(0xFF00E5FF), Color(0xFFD500F9)],
    tipColor: Color(0xFF00E5FF),
    auraColor: Color(0xDD00E5FF),
    ballTrailColor: Color(0xFF18FFFF),
    animeConcept: CueAnimeConcept.cyberNeo,
  );

  static const CueModel arcaneAstral = CueModel(
    id: 'arcane_astral',
    name: 'Trượng Ma Pháp Tinh Tú',
    rarity: CueRarity.legendary,
    requiredLevel: 28,
    priceDiamonds: 350,
    description: 'Pháp bảo của đại phù thủy cổ đại, kết tinh từ pha lê mana đa chiều tỏa hào quang tinh vân vũ trụ.',
    passivePerk: 'Astral Focus: Kéo dài tia ngắm ma thuật và hiển thị vòng tròn ma pháp va chạm.',
    baseStats: CueStats(force: 9.0, aim: 9.8, spin: 9.0, time: 8.5),
    shaftColors: [Color(0xFFE1BEE7), Color(0xFF7C4DFF), Color(0xFF311B92)],
    handleColors: [Color(0xFF1A237E), Color(0xFFFFD700), Color(0xFF4A148C)],
    tipColor: Color(0xFFE040FB),
    auraColor: Color(0xEEE040FB),
    ballTrailColor: Color(0xFFB388FF),
    animeConcept: CueAnimeConcept.arcaneMagic,
  );

  static const CueModel shadowMonarch = CueModel(
    id: 'shadow_monarch',
    name: 'Lưỡi Hái Quân Vương Bóng Tối',
    rarity: CueRarity.legendary,
    requiredLevel: 32,
    priceDiamonds: 500,
    description: 'Vũ khí thần thoại thức tỉnh từ lãnh địa hắc ám, bao phủ bởi ngọn lửa tím và sương mù linh hồn bất diệt.',
    passivePerk: 'Shadow Extraction: Tăng vọt 30% hiệu ứng xoáy áp-phê trô lùi cực mạnh.',
    baseStats: CueStats(force: 9.5, aim: 9.0, spin: 10.0, time: 7.5),
    shaftColors: [Color(0xFF212121), Color(0xFF651FFF), Color(0xFF0D001A)],
    handleColors: [Color(0xFF121212), Color(0xFF4527A0), Color(0xFF000000)],
    tipColor: Color(0xFF7C4DFF),
    auraColor: Color(0xEE7C4DFF),
    ballTrailColor: Color(0xFF651FFF),
    animeConcept: CueAnimeConcept.shadowVoid,
  );

  static const CueModel sakuraBloom = CueModel(
    id: 'sakura_bloom',
    name: 'Thần Kiếm Hoa Anh Đào',
    rarity: CueRarity.epic,
    requiredLevel: 10,
    priceCoins: 38000,
    description: 'Chế tác từ gỗ anh đào nghìn năm sơn mài xà cừ trắng hồng, tỏa cánh hoa rơi mỗi nhịp vung cơ.',
    passivePerk: 'Petal Dance: Cú đánh siêu êm ái, giảm rung lắc và triệt tiêu sai lệch góc.',
    baseStats: CueStats(force: 7.0, aim: 8.0, spin: 7.5, time: 6.0),
    shaftColors: [Color(0xFFFCE4EC), Color(0xFFF48FB1), Color(0xFFC2185B)],
    handleColors: [Color(0xFF880E4F), Color(0xFFFFD54F), Color(0xFF4A148C)],
    tipColor: Color(0xFFFF80AB),
    auraColor: Color(0xDDFF80AB),
    ballTrailColor: Color(0xFFFF4081),
    animeConcept: CueAnimeConcept.sakuraZen,
  );

  static const CueModel mechaEvangel = CueModel(
    id: 'mecha_evangel',
    name: 'Thương Phá Giáp EVA-Core',
    rarity: CueRarity.legendary,
    requiredLevel: 24,
    priceCoins: 90000,
    description: 'Mẫu cơ vũ khí nhân tạo sinh học màu tím lục neon đặc trưng cùng lá chắn năng lượng tuyệt đối.',
    passivePerk: 'AT-Field Crash: Xung lực phá bi kinh hoàng và lực đàn hồi nảy băng vượt trội.',
    baseStats: CueStats(force: 9.8, aim: 8.5, spin: 8.0, time: 7.5),
    shaftColors: [Color(0xFF4A148C), Color(0xFF76FF03), Color(0xFF1B5E20)],
    handleColors: [Color(0xFF263238), Color(0xFFFF6D00), Color(0xFF37474F)],
    tipColor: Color(0xFF76FF03),
    auraColor: Color(0xEE76FF03),
    ballTrailColor: Color(0xFF64DD17),
    animeConcept: CueAnimeConcept.mechaGundam,
  );

  // Aliases
  static const CueModel mapleWood = titanStriker;
  static const CueModel amberFire = frostbite;
  static const CueModel stormNeon = goldenBull;
  static const CueModel blackDiamond = cyberNeo;

  static const List<CueModel> allCues = [
    standardCue,
    titanStriker,
    sakuraBloom,
    frostbite,
    nichirinKatana,
    cyberRebellion,
    goldenBull,
    mechaEvangel,
    cyberNeo,
    phoenixFlame,
    arcaneAstral,
    shadowMonarch,
    dragonGod,
  ];

  static CueModel getById(String id) {
    return allCues.firstWhere(
      (c) => c.id == id,
      orElse: () => allCues.first,
    );
  }
}
