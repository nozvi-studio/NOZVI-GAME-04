import 'package:flutter/material.dart';
import '../services/language_service.dart';

enum AchievementDifficulty {
  easy,
  medium,
  hard,
  expert,
  legendary,
}

extension AchievementDifficultyExt on AchievementDifficulty {
  String get label {
    return LanguageService.instance.localizeAchievementDifficulty(name, switch (this) {
      AchievementDifficulty.easy => 'Dễ',
      AchievementDifficulty.medium => 'Trung Bình',
      AchievementDifficulty.hard => 'Khó',
      AchievementDifficulty.expert => 'Siêu Khó',
      AchievementDifficulty.legendary => 'Huyền Thoại',
    });
  }


  int get defaultRewardXP {
    switch (this) {
      case AchievementDifficulty.easy:
        return 60;
      case AchievementDifficulty.medium:
        return 150;
      case AchievementDifficulty.hard:
        return 350;
      case AchievementDifficulty.expert:
        return 700;
      case AchievementDifficulty.legendary:
        return 1800;
    }
  }

  Color get color {
    switch (this) {
      case AchievementDifficulty.easy:
        return const Color(0xFF66BB6A);
      case AchievementDifficulty.medium:
        return const Color(0xFF42A5F5);
      case AchievementDifficulty.hard:
        return const Color(0xFFFFA726);
      case AchievementDifficulty.expert:
        return const Color(0xFFAB47BC);
      case AchievementDifficulty.legendary:
        return const Color(0xFFFFD700);
    }
  }
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementDifficulty difficulty;
  final int rewardXP;
  final int targetValue;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.rewardXP,
    this.targetValue = 1,
  });

  String get localizedTitle => LanguageService.instance.localizeAchievementTitle(id, title);
  String get localizedDescription => LanguageService.instance.localizeAchievementDescription(id, description);
}


class AchievementCatalog {
  static const List<AchievementModel> allAchievements = [
    // =========================================================================
    // 1. DỄ (EASY) - 15 Thành tựu
    // =========================================================================
    AchievementModel(
      id: 'first_win',
      title: 'Phát Cơ Đầu Tiên',
      description: 'Giành chiến thắng trận đấu bida đầu tiên của bạn.',
      icon: Icons.emoji_events,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
    ),
    AchievementModel(
      id: 'cue_enthusiast',
      title: 'Tín Đồ Bida',
      description: 'Sở hữu ít nhất 2 cây gậy cơ trong Cửa Hàng.',
      icon: Icons.sports_baseball,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
      targetValue: 2,
    ),
    AchievementModel(
      id: 'spin_trick',
      title: 'Biến Hóa Điểm Chạm',
      description: 'Tùy chỉnh kỹ thuật Áp-phê (Cu-lê hoặc Trô bóng) trong trận đấu.',
      icon: Icons.rotate_right,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
    ),
    AchievementModel(
      id: 'first_wealth',
      title: 'Đồng Tiền Đầu Tiên',
      description: 'Tích lũy đạt mốc 5.000 Vàng trong tài khoản.',
      icon: Icons.monetization_on,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
      targetValue: 5000,
    ),
    AchievementModel(
      id: 'reach_level_3',
      title: 'Tân Binh Triển Vọng',
      description: 'Nâng cấp nhân vật đạt Cấp độ 3 trong sự nghiệp.',
      icon: Icons.grade,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'reach_level_5',
      title: 'Nhập Môn Xuất Sắc',
      description: 'Nâng cấp nhân vật đạt Cấp độ 5.',
      icon: Icons.military_tech,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 70,
      targetValue: 5,
    ),
    AchievementModel(
      id: 'cue_upgrade_first',
      title: 'Khởi Đầu Rèn Giũa',
      description: 'Nâng cấp một cây gậy cơ bất kỳ lên Cấp 2 lần đầu tiên.',
      icon: Icons.build,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
    ),
    AchievementModel(
      id: 'cue_upgrade_level_3',
      title: 'Tôi Luyện Thép Tinh',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 3.',
      icon: Icons.trending_up,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 70,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'bot_stage_1',
      title: 'Thử Thách Khởi Khởi',
      description: 'Vượt qua Ải 1 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.smart_toy,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
      targetValue: 1,
    ),
    AchievementModel(
      id: 'bot_stage_2',
      title: 'Đấu Sĩ Tự Tin',
      description: 'Vượt qua Ải 2 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.android,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 70,
      targetValue: 2,
    ),
    AchievementModel(
      id: 'tournament_entry',
      title: 'Chào Sân Tournament',
      description: 'Chiến thắng trận mở màn Bracket 1 của Giải đấu Tournament.',
      icon: Icons.tour,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 70,
      targetValue: 1,
    ),
    AchievementModel(
      id: 'trickshot_first',
      title: 'Phát Cơ Nghệ Thuật',
      description: 'Chinh phục thành công 1 Thế Đánh Huyền Thoại của cao thủ thế giới.',
      icon: Icons.auto_awesome,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 70,
      targetValue: 1,
    ),
    AchievementModel(
      id: 'first_diamond',
      title: 'Thợ Săn Bảo Thạch',
      description: 'Tích lũy đạt từ 30 Kim Cương trở lên.',
      icon: Icons.diamond,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
      targetValue: 30,
    ),
    AchievementModel(
      id: 'change_profile_cue',
      title: 'Phong Cách Cơ Thủ',
      description: 'Trang bị một cây gậy cơ mới khác với gậy mặc định.',
      icon: Icons.sports,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
    ),
    AchievementModel(
      id: 'explore_daily_puzzle',
      title: 'Khám Phá Thế Bi',
      description: 'Thử sức giải bài toán Thế Bi Hàng Ngày (Daily Puzzle).',
      icon: Icons.lightbulb,
      difficulty: AchievementDifficulty.easy,
      rewardXP: 60,
    ),

    // =========================================================================
    // 2. TRUNG BÌNH (MEDIUM) - 15 Thành tựu
    // =========================================================================
    AchievementModel(
      id: 'combo_hunter',
      title: 'Thợ Săn Combo',
      description: 'Thực hiện chuỗi ăn Combo từ 2 bi cùng nhóm trở lên trong 1 cơ.',
      icon: Icons.flash_on,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
    ),
    AchievementModel(
      id: 'daily_puzzle_clear',
      title: 'Bậc Thầy Giải Thế',
      description: 'Hoàn thành thử thách Thế Bi Hàng Ngày (Daily Trickshot).',
      icon: Icons.event_available,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
    ),
    AchievementModel(
      id: 'win_streak_3',
      title: 'Tam Liên Thắng',
      description: 'Giành tổng cộng từ 3 trận thắng trở lên.',
      icon: Icons.military_tech,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'win_10',
      title: 'Thập Trận Thăng Hoa',
      description: 'Giành tổng cộng từ 10 trận thắng vẻ vang trở lên.',
      icon: Icons.looks_one,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 160,
      targetValue: 10,
    ),
    AchievementModel(
      id: 'coins_10k',
      title: 'Phú Hào Tập Sự',
      description: 'Tích lũy tài sản đạt từ 10.000 Vàng trong két sắt.',
      icon: Icons.savings,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
      targetValue: 10000,
    ),
    AchievementModel(
      id: 'coins_20k',
      title: 'Đại Lợi Kim Ngân',
      description: 'Tích lũy tài sản đạt từ 20.000 Vàng trong két sắt.',
      icon: Icons.account_balance_wallet,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 160,
      targetValue: 20000,
    ),
    AchievementModel(
      id: 'reach_level_8',
      title: 'Chiến Binh Dày Dạn',
      description: 'Nâng cấp trình độ nhân vật đạt từ Cấp 8 trở lên.',
      icon: Icons.verified_user,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
      targetValue: 8,
    ),
    AchievementModel(
      id: 'cue_upgrade_level_5',
      title: 'Thần Khí Xuất Thế',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 5.',
      icon: Icons.hardware,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 180,
      targetValue: 5,
    ),
    AchievementModel(
      id: 'bot_stage_3',
      title: 'Vượt Khó Vươn Lên',
      description: 'Vượt qua Ải 3 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.bolt,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'bot_stage_4',
      title: 'Tay Cơ Bản Lĩnh',
      description: 'Vượt qua Ải 4 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.psychology,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 160,
      targetValue: 4,
    ),
    AchievementModel(
      id: 'bot_stage_5',
      title: 'Bứt Phá Giới Hạn',
      description: 'Vượt qua Ải 5 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.shield,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 180,
      targetValue: 5,
    ),
    AchievementModel(
      id: 'tournament_bracket_2',
      title: 'Vé Vào Tứ Kết',
      description: 'Vượt qua Bracket 2 trong Giải đấu Tournament.',
      icon: Icons.card_membership,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 160,
      targetValue: 2,
    ),
    AchievementModel(
      id: 'tournament_bracket_3',
      title: 'Anh Hùng Tứ Cường',
      description: 'Vượt qua Bracket 3 để ghi tên vào Top 4 Tournament.',
      icon: Icons.flag,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 180,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'trickshot_master_5',
      title: 'Bàn Tay Phù Thủy',
      description: 'Chinh phục thành công 5 Thế Đánh Huyền Thoại thế giới.',
      icon: Icons.workspace_premium,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 180,
      targetValue: 5,
    ),
    AchievementModel(
      id: 'medals_showcase_3',
      title: 'Vinh Danh Tam Bảo',
      description: 'Ghim đủ 3 Huy chương danh dự lên Profile cá nhân.',
      icon: Icons.bookmark_added,
      difficulty: AchievementDifficulty.medium,
      rewardXP: 150,
      targetValue: 3,
    ),

    // =========================================================================
    // 3. KHÓ (HARD) - 15 Thành tựu
    // =========================================================================
    AchievementModel(
      id: 'cue_collector',
      title: 'Nhà Sưu Tập Cơ Thủ',
      description: 'Mở khóa và sở hữu từ 4 cây gậy cơ trở lên trong bộ sưu tập.',
      icon: Icons.shopping_bag,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 4,
    ),
    AchievementModel(
      id: 'rich_player',
      title: 'Đại Gia Phố Bida',
      description: 'Tích lũy tài sản đạt từ 25.000 Vàng trở lên.',
      icon: Icons.monetization_on,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 25000,
    ),
    AchievementModel(
      id: 'multiplayer_veteran',
      title: 'Sát Thủ Đối Kháng',
      description: 'Chiến thắng trận đấu mạng nhiều người chơi (Local/Online).',
      icon: Icons.wifi_tethering,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
    ),
    AchievementModel(
      id: 'win_25',
      title: 'Cao Thủ Lão Luyện',
      description: 'Giành tổng cộng từ 25 trận thắng vẻ vang.',
      icon: Icons.stars,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 25,
    ),
    AchievementModel(
      id: 'win_50',
      title: 'Chiến Tướng Bàn Xanh',
      description: 'Giành tổng cộng từ 50 trận thắng vẻ vang.',
      icon: Icons.sports_score,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 400,
      targetValue: 50,
    ),
    AchievementModel(
      id: 'reach_level_15',
      title: 'Bậc Thầy Bàn Bida',
      description: 'Nâng cấp nhân vật đạt Cấp 15 (Lv.15).',
      icon: Icons.military_tech,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 15,
    ),
    AchievementModel(
      id: 'reach_level_20',
      title: 'Danh Chấn Giang Hồ',
      description: 'Nâng cấp nhân vật đạt Cấp 20 (Lv.20).',
      icon: Icons.shield_moon,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 400,
      targetValue: 20,
    ),
    AchievementModel(
      id: 'coins_50k',
      title: 'Thương Gia Phố Cổ',
      description: 'Tích lũy tài sản đạt từ 50.000 Vàng trong két sắt.',
      icon: Icons.account_balance,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 50000,
    ),
    AchievementModel(
      id: 'coins_75k',
      title: 'Kim Khố Đầy Ắp',
      description: 'Tích lũy tài sản đạt từ 75.000 Vàng trong két sắt.',
      icon: Icons.paid,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 400,
      targetValue: 75000,
    ),
    AchievementModel(
      id: 'cue_upgrade_level_7',
      title: 'Đỉnh Cao Chế Tác',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 7.',
      icon: Icons.auto_fix_high,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 7,
    ),
    AchievementModel(
      id: 'cue_upgrade_level_8',
      title: 'Tuyệt Sắc Thần Cơ',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 8.',
      icon: Icons.construction,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 400,
      targetValue: 8,
    ),
    AchievementModel(
      id: 'bot_stage_6',
      title: 'Phá Vỡ Chiến Thuật',
      description: 'Vượt qua Ải 6 trong Chiến Dịch Thử Thách Bot.',
      icon: Icons.view_in_ar,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 6,
    ),
    AchievementModel(
      id: 'tournament_bracket_4',
      title: 'Bước Vào Chung Kết',
      description: 'Chiến thắng Bán Kết Bracket 4 để tiến vào Chung Kết Tournament.',
      icon: Icons.emoji_events,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 400,
      targetValue: 4,
    ),
    AchievementModel(
      id: 'trickshot_master_10',
      title: 'Bách Nghệ Kỳ Tài',
      description: 'Chinh phục từ 10 Thế Đánh Huyền Thoại trở lên.',
      icon: Icons.stars,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 380,
      targetValue: 10,
    ),
    AchievementModel(
      id: 'medals_showcase_5',
      title: 'Phòng Danh Dự Tỏa Sáng',
      description: 'Ghim trọn vẹn đủ 5 Huy chương danh giá trên Profile.',
      icon: Icons.auto_awesome,
      difficulty: AchievementDifficulty.hard,
      rewardXP: 350,
      targetValue: 5,
    ),

    // =========================================================================
    // 4. SIÊU KHÓ (EXPERT) - 10 Thành tựu
    // =========================================================================
    AchievementModel(
      id: 'bot_campaign_clear',
      title: 'Khuất Phục Cao Thủ Bot',
      description: 'Vượt qua trọn vẹn 7 Ải Thử Thách Bot Campaign.',
      icon: Icons.smart_toy,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 700,
      targetValue: 7,
    ),
    AchievementModel(
      id: 'cue_level_max',
      title: 'Tuyệt Đỉnh Thần Binh',
      description: 'Nâng cấp bất kỳ cây gậy cơ nào đạt cấp độ tối đa (Level 10).',
      icon: Icons.upgrade,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 700,
    ),
    AchievementModel(
      id: 'reach_level_10',
      title: 'Cơ Thủ Kỳ Cựu',
      description: 'Nâng cấp trình độ nhân vật đạt từ Cấp 10 (Lv.10) trở lên.',
      icon: Icons.stars,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 700,
      targetValue: 10,
    ),
    AchievementModel(
      id: 'win_100',
      title: 'Trăm Trận Trăm Thắng',
      description: 'Đạt tổng cộng từ 100 trận thắng trong sự nghiệp.',
      icon: Icons.military_tech,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 750,
      targetValue: 100,
    ),
    AchievementModel(
      id: 'win_200',
      title: 'Bách Chiến Thần Binh',
      description: 'Đạt tổng cộng từ 200 trận thắng oanh liệt.',
      icon: Icons.shield,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 850,
      targetValue: 200,
    ),
    AchievementModel(
      id: 'reach_level_30',
      title: 'Tinh Anh Quốc Tế',
      description: 'Đạt Cấp độ người chơi Lv.30 trở lên.',
      icon: Icons.workspace_premium,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 750,
      targetValue: 30,
    ),
    AchievementModel(
      id: 'reach_level_50',
      title: 'Siêu Cấp Huyền Thoại',
      description: 'Đạt Cấp độ người chơi Lv.50 trở lên.',
      icon: Icons.diamond,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 850,
      targetValue: 50,
    ),
    AchievementModel(
      id: 'coins_200k',
      title: 'Triệu Phú Đại Tài',
      description: 'Tích lũy tài sản đạt từ 200.000 Vàng trong két sắt.',
      icon: Icons.account_balance,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 750,
      targetValue: 200000,
    ),
    AchievementModel(
      id: 'bot_stage_9',
      title: 'Khắc Tinh Bot Thượng Đẳng',
      description: 'Vượt qua Ải 9 khó khăn trong Chiến Dịch Bot Campaign.',
      icon: Icons.security,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 800,
      targetValue: 9,
    ),
    AchievementModel(
      id: 'bot_stage_10',
      title: 'Đại Thắng Boss Cuối',
      description: 'Vượt qua Ải 10 Thử Thách Bot Tối Thượng.',
      icon: Icons.sports_mma,
      difficulty: AchievementDifficulty.expert,
      rewardXP: 900,
      targetValue: 10,
    ),

    // =========================================================================
    // 5. HUYỀN THOẠI (LEGENDARY) - 5 Thành tựu
    // =========================================================================
    AchievementModel(
      id: 'tournament_champion_legend',
      title: 'Vua Giải Đấu 5 Brackets',
      description: 'Vượt qua toàn bộ các vòng đấu Brackets khốc liệt và nâng cao cúp Vô Địch!',
      icon: Icons.workspace_premium,
      difficulty: AchievementDifficulty.legendary,
      rewardXP: 1800,
    ),
    AchievementModel(
      id: 'billiard_god',
      title: 'Huyền Thoại Bida Toàn Năng',
      description: 'Sở hữu trên 100.000 Vàng và đạt 50 trận thắng vẻ vang.',
      icon: Icons.auto_awesome,
      difficulty: AchievementDifficulty.legendary,
      rewardXP: 1800,
      targetValue: 50,
    ),
    AchievementModel(
      id: 'cue_arsenal_full',
      title: 'Bộ Sưu Tập Thần Khí',
      description: 'Mở khóa và sở hữu toàn bộ 7 cây gậy cơ trong Cửa hàng.',
      icon: Icons.category,
      difficulty: AchievementDifficulty.legendary,
      rewardXP: 2000,
      targetValue: 7,
    ),
    AchievementModel(
      id: 'tournament_multi_champ',
      title: 'Tam Quan Vương Tournament',
      description: 'Giành chức Vô Địch Giải Đấu Tournament từ 3 lần trở lên.',
      icon: Icons.military_tech,
      difficulty: AchievementDifficulty.legendary,
      rewardXP: 2200,
      targetValue: 3,
    ),
    AchievementModel(
      id: 'billiard_emperor',
      title: 'Đấng Tối Cao Bàn Bida',
      description: 'Đạt Cấp 70+, sở hữu trên 500.000 Vàng và 100 trận thắng.',
      icon: Icons.whatshot,
      difficulty: AchievementDifficulty.legendary,
      rewardXP: 2500,
      targetValue: 100,
    ),
  ];

  static AchievementModel? getById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
