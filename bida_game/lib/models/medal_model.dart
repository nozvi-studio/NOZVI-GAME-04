import 'package:flutter/material.dart';
import '../services/language_service.dart';

enum MedalRarity {
  bronze,
  silver,
  gold,
  diamond,
  mythic,
}

extension MedalRarityExt on MedalRarity {
  String get label {
    return LanguageService.instance.localizeMedalRarity(name, switch (this) {
      MedalRarity.bronze => 'Đồng',
      MedalRarity.silver => 'Bạc',
      MedalRarity.gold => 'Vàng',
      MedalRarity.diamond => 'Kim Cương',
      MedalRarity.mythic => 'Thần Thoại',
    });
  }


  List<Color> get gradientColors {
    switch (this) {
      case MedalRarity.bronze:
        return const [Color(0xFFCD7F32), Color(0xFF8D5524)];
      case MedalRarity.silver:
        return const [Color(0xFFCFD8DC), Color(0xFF78909C)];
      case MedalRarity.gold:
        return const [Color(0xFFFFD54F), Color(0xFFFF8F00)];
      case MedalRarity.diamond:
        return const [Color(0xFF80DEEA), Color(0xFF00ACC1)];
      case MedalRarity.mythic:
        return const [Color(0xFFFF4081), Color(0xFF7C4DFF)];
    }
  }

  Color get glowColor {
    switch (this) {
      case MedalRarity.bronze:
        return const Color(0xFFCD7F32);
      case MedalRarity.silver:
        return const Color(0xFFB0BEC5);
      case MedalRarity.gold:
        return const Color(0xFFFFD54F);
      case MedalRarity.diamond:
        return const Color(0xFF00E5FF);
      case MedalRarity.mythic:
        return const Color(0xFFE040FB);
    }
  }
}

class MedalModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final MedalRarity rarity;
  final String unlockRequirement;

  const MedalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.unlockRequirement,
  });

  String get localizedName => LanguageService.instance.localizeMedalName(id, name);
  String get localizedDescription => LanguageService.instance.localizeMedalDescription(id, description);
  String get localizedRequirement => LanguageService.instance.localizeMedalRequirement(id, unlockRequirement);
}


class MedalCatalog {
  static const List<MedalModel> allMedals = [
    // =========================================================================
    // 1. ĐỒNG (BRONZE) - 8 Huy chương
    // =========================================================================
    MedalModel(
      id: 'bronze_champion',
      name: 'Cơ Thủ Tinh Anh',
      description: 'Ghi dấu ấn những bước đầu tiên trên đấu trường bi-a chuyên nghiệp.',
      icon: Icons.verified,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Chiến thắng trận đấu đầu tiên',
    ),
    MedalModel(
      id: 'bot_cadet',
      name: 'Huy Hiệu Tân Binh Bot',
      description: 'Vượt qua ải đầu tiên trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.smart_toy,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Vượt qua ải 1 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'bot_fighter',
      name: 'Huy Hiệu Chiến Sĩ Bot',
      description: 'Thể hiện bản lĩnh kiên cường khi khuất phục Bot ải 3.',
      icon: Icons.shield,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Vượt qua ải 3 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'tournament_quarter',
      name: 'Huy Hiệu Tứ Trụ',
      description: 'Vượt qua Bracket 2 để tiến vào Tứ Kết Tournament danh giá.',
      icon: Icons.emoji_events,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Vượt qua Bracket 2 của Tournament',
    ),
    MedalModel(
      id: 'cue_apprentice',
      name: 'Thợ Rèn Cơ Tập Sự',
      description: 'Rèn đúc và nâng cấp một cây gậy cơ đạt mốc Cấp 3.',
      icon: Icons.build,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Nâng cấp bất kỳ cây gậy nào lên Cấp 3',
    ),
    MedalModel(
      id: 'trickshot_apprentice',
      name: 'Khám Phá Thế Bi',
      description: 'Chinh phục thành công 1 Thế Đánh Huyền Thoại kinh điển.',
      icon: Icons.track_changes,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Hoàn thành 1 Thế Đánh Huyền Thoại',
    ),
    MedalModel(
      id: 'rising_star',
      name: 'Ngôi Sao Đang Lên',
      description: 'Minh chứng cho bước tiến vượt bậc đạt Cấp độ 5.',
      icon: Icons.stars,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Đạt Cấp độ người chơi Lv.5 trở lên',
    ),
    MedalModel(
      id: 'cue_collector_bronze',
      name: 'Bộ Sưu Tập Đồng',
      description: 'Bổ sung thêm gậy cơ vào kho vũ khí cá nhân.',
      icon: Icons.sports,
      rarity: MedalRarity.bronze,
      unlockRequirement: 'Sở hữu từ 2 cây gậy cơ trở lên',
    ),

    // =========================================================================
    // 2. BẠC (SILVER) - 8 Huy chương
    // =========================================================================
    MedalModel(
      id: 'tournament_semis',
      name: 'Huy Chương Tứ Cường',
      description: 'Vượt qua vòng Tứ Kết và ghi tên mình vào Bán Kết Bracket 4.',
      icon: Icons.military_tech,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Vượt qua Bracket 3 để tiến vào Bán Kết Tournament',
    ),
    MedalModel(
      id: 'wealthy_striker',
      name: 'Triệu Phú Phố Bida',
      description: 'Sở hữu khối tài sản từ 20.000 Vàng trong két sắt cá nhân.',
      icon: Icons.monetization_on,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Tích lũy đạt trên 20.000 Vàng',
    ),
    MedalModel(
      id: 'bot_challenger',
      name: 'Huy Hiệu Thách Đấu Bot',
      description: 'Bứt phá vượt qua Ải 5 trong Chiến Dịch Bot.',
      icon: Icons.bolt,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Vượt qua ải 5 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'trickshot_virtuoso',
      name: 'Bậc Thầy Đường Cơ',
      description: 'Chinh phục thành công 5 Thế Đánh Huyền Thoại đỉnh cao.',
      icon: Icons.lens_blur,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Hoàn thành 5 Thế Đánh Huyền Thoại',
    ),
    MedalModel(
      id: 'veteran_striker',
      name: 'Cơ Thủ Lão Thành',
      description: 'Khẳng định sự dày dạn với 15 trận thắng vẻ vang.',
      icon: Icons.sports_score,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Đạt từ 15 trận thắng trở lên',
    ),
    MedalModel(
      id: 'cue_artisan',
      name: 'Thợ Thủ Công Bida',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt mốc Cấp 4.',
      icon: Icons.hardware,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Nâng cấp bất kỳ cây gậy nào lên Cấp 4',
    ),
    MedalModel(
      id: 'silver_treasury',
      name: 'Ngân Khố Hoàng Kim',
      description: 'Tích lũy khối tài sản trên 50.000 Vàng.',
      icon: Icons.savings,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Tích lũy đạt trên 50.000 Vàng',
    ),
    MedalModel(
      id: 'english_spin_master',
      name: 'Thần Xoáy Áp-Phê',
      description: 'Tùy chỉnh kỹ thuật Áp-phê (Cu-lê hoặc Trô bóng) điệu nghệ trong thi đấu.',
      icon: Icons.rotate_right,
      rarity: MedalRarity.silver,
      unlockRequirement: 'Sử dụng kỹ thuật xoáy bóng Áp-phê trong trận đấu',
    ),

    // =========================================================================
    // 3. VÀNG (GOLD) - 10 Huy chương
    // =========================================================================
    MedalModel(
      id: 'tournament_runner_up',
      name: 'Huy Chương Á Quân',
      description: 'Khẳng định bản lĩnh kiên cường khi bước chân vào trận Đại Chung Kết Bracket 5.',
      icon: Icons.workspace_premium,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Lọt vào trận Chung Kết Bracket 5 của Tournament',
    ),
    MedalModel(
      id: 'sharpshooter',
      name: 'Huy Chương Thiện Xạ',
      description: 'Dành cho cơ thủ có nhãn quan siêu phàm, ghi combo ăn nhiều bi liên hoàn.',
      icon: Icons.gps_fixed,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Thực hiện chuỗi ăn Combo bi trong trận đấu',
    ),
    MedalModel(
      id: 'cue_master',
      name: 'Bậc Thầy Gậy Cơ',
      description: 'Sở hữu và rèn đúc gậy cơ đạt mốc nâng cấp Level 5 trở lên.',
      icon: Icons.hardware,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Nâng cấp bất kỳ cây gậy nào lên cấp 5+',
    ),
    MedalModel(
      id: 'grandmaster',
      name: 'Đại Kiện Tướng Bida',
      description: 'Minh chứng cho đẳng cấp cơ thủ kỳ cựu đạt Cấp độ 10+.',
      icon: Icons.stars,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Đạt Cấp độ người chơi Lv.10 trở lên',
    ),
    MedalModel(
      id: 'undefeated_spree',
      name: 'Bất Khả Chiến Bại',
      description: 'Giành chuỗi 5 trận thắng oanh liệt liên tiếp.',
      icon: Icons.flash_on,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Giành từ 5 trận thắng liên tiếp',
    ),
    MedalModel(
      id: 'centurion_victor',
      name: 'Cơ Thủ Bách Thắng',
      description: 'Đạt mốc 30 trận thắng vẻ vang trong sự nghiệp.',
      icon: Icons.military_tech,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Đạt từ 30 trận thắng trở lên',
    ),
    MedalModel(
      id: 'cue_collector_gold',
      name: 'Nhà Sưu Tập Vàng',
      description: 'Mở khóa và sở hữu từ 4 cây gậy cơ trong tủ đồ.',
      icon: Icons.shopping_bag,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Sở hữu từ 4 cây gậy cơ trở lên',
    ),
    MedalModel(
      id: 'master_duel_victor',
      name: 'Khắc Tinh Bot Thượng Thừa',
      description: 'Vượt qua ải 8 đầy hiểm hóc trong Chiến Dịch Bot.',
      icon: Icons.psychology,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Vượt qua ải 8 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'golden_treasury',
      name: 'Đại Phú Hào Bàn Xanh',
      description: 'Tích lũy khối tài sản trên 100.000 Vàng trong két.',
      icon: Icons.account_balance,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Tích lũy đạt trên 100.000 Vàng',
    ),
    MedalModel(
      id: 'profile_perfection',
      name: 'Vinh Dự Ngũ Tinh',
      description: 'Ghim trọn vẹn đủ 5 Huy Chương Danh Dự lên Profile cá nhân.',
      icon: Icons.auto_awesome,
      rarity: MedalRarity.gold,
      unlockRequirement: 'Ghim đủ 5 Huy Chương trên Profile',
    ),

    // =========================================================================
    // 4. KIM CƯƠNG (DIAMOND) - 8 Huy chương
    // =========================================================================
    MedalModel(
      id: 'trickshot_master',
      name: 'Thần Cơ Diệu Toán',
      description: 'Giải mã thành công thế bi hiểm hóc của nhiệm vụ Hàng Ngày.',
      icon: Icons.diamond,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Chiến thắng chế độ Thế Bi Hàng Ngày',
    ),
    MedalModel(
      id: 'bot_slayer',
      name: 'Huy Hiệu Trùm Bot',
      description: 'Đánh bại Boss Bot cao nhất trong chuỗi 7 Ải Thử Thách Chiến Dịch.',
      icon: Icons.smart_toy,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Vượt qua ải 7 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'bot_annihilator',
      name: 'Kẻ Hủy Diệt Bot',
      description: 'Đánh bại đối thủ Bot ải 9 đỉnh cao của Chiến Dịch.',
      icon: Icons.security,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Vượt qua ải 9 trong Chiến Dịch Bot',
    ),
    MedalModel(
      id: 'trickshot_legend',
      name: 'Huân Chương Phù Thủy Bi',
      description: 'Chinh phục từ 10 Thế Đánh Huyền Thoại kinh điển của các cơ thủ thế giới.',
      icon: Icons.auto_awesome,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Hoàn thành 10 Thế Đánh Huyền Thoại',
    ),
    MedalModel(
      id: 'cue_god_forge',
      name: 'Bậc Thầy Đúc Thần Khí',
      description: 'Rèn luyện và nâng cấp bất kỳ cây gậy cơ nào đạt cấp độ tối đa (Level 10).',
      icon: Icons.upgrade,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Nâng cấp bất kỳ cây gậy nào lên Cấp tối đa (Level 10)',
    ),
    MedalModel(
      id: 'hall_of_fame',
      name: 'Đại Sảnh Danh Vọng',
      description: 'Minh chứng cho cơ thủ kiệt xuất đạt Cấp độ Lv.25 trở lên.',
      icon: Icons.military_tech,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Đạt Cấp độ người chơi Lv.25 trở lên',
    ),
    MedalModel(
      id: 'legendary_champion',
      name: 'Quán Quân Trăm Trận',
      description: 'Ghi dấu ấn vang dội với 75 trận thắng trong sự nghiệp.',
      icon: Icons.emoji_events,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Đạt từ 75 trận thắng trở lên',
    ),
    MedalModel(
      id: 'diamond_royalty',
      name: 'Hoàng Gia Kim Cương',
      description: 'Tích lũy đạt trên 100 Kim Cương quý giá.',
      icon: Icons.diamond,
      rarity: MedalRarity.diamond,
      unlockRequirement: 'Tích lũy đạt trên 100 Kim Cương',
    ),

    // =========================================================================
    // 5. THẦN THOẠI (MYTHIC) - 6 Huy chương
    // =========================================================================
    MedalModel(
      id: 'tournament_champion',
      name: 'Cúp Quán Quân Tournament',
      description: 'Danh hiệu cao quý nhất dành cho cơ thủ thống trị cả 5 Brackets của giải đấu.',
      icon: Icons.emoji_events,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Vô địch chế độ Giải Đấu Tournament 5 Brackets',
    ),
    MedalModel(
      id: 'tournament_dynasty',
      name: 'Cúp Hoàng Triều Tournament',
      description: 'Thống trị giải đấu với từ 3 lần vô địch Tournament trở lên.',
      icon: Icons.military_tech,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Vô địch Tournament từ 3 lần trở lên',
    ),
    MedalModel(
      id: 'bot_overlord',
      name: 'Huân Chương Bá Chủ AI',
      description: 'Quét sạch toàn bộ 10 Ải Chiến Dịch Thử Thách Bot.',
      icon: Icons.sports_mma,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Vượt qua trọn vẹn Ải 10 Bot Campaign',
    ),
    MedalModel(
      id: 'cue_collector_mythic',
      name: 'Kho Báu Vạn Cây',
      description: 'Mở khóa và sở hữu trọn bộ 7 cây gậy cơ huyền thoại của trò chơi.',
      icon: Icons.category,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Sở hữu trọn bộ 7 cây gậy cơ',
    ),
    MedalModel(
      id: 'immortal_sovereign',
      name: 'Đấng Tối Cao Bida',
      description: 'Cơ thủ tối thượng đạt Cấp độ người chơi Lv.50 trở lên.',
      icon: Icons.whatshot,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Đạt Cấp độ người chơi Lv.50 trở lên',
    ),
    MedalModel(
      id: 'trickshot_immortal',
      name: 'Vương Huy Hoàng Gia Trickshot',
      description: 'Chinh phục từ 25 Thế Đánh Huyền Thoại của các huyền thoại thế giới.',
      icon: Icons.stars,
      rarity: MedalRarity.mythic,
      unlockRequirement: 'Hoàn thành 25 Thế Đánh Huyền Thoại',
    ),
  ];

  static MedalModel? getById(String id) {
    try {
      return allMedals.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
