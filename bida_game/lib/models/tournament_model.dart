import 'cue_model.dart';

class TournamentBracketStage {
  final int bracketNumber; // 1 to 6
  final String title;
  final String roundName;
  final String opponentName;
  final int opponentLevel;
  final String opponentAvatarAsset;
  final CueModel opponentCue;
  final int botDifficultyRating; // 1 to 10
  final int coinReward;
  final int xpReward;
  final String? bonusMedalId;
  final String description;

  const TournamentBracketStage({
    required this.bracketNumber,
    required this.title,
    required this.roundName,
    required this.opponentName,
    required this.opponentLevel,
    required this.opponentAvatarAsset,
    required this.opponentCue,
    required this.botDifficultyRating,
    required this.coinReward,
    required this.xpReward,
    this.bonusMedalId,
    required this.description,
  });
}

class TournamentCatalog {
  static const List<TournamentBracketStage> brackets = [
    // Bracket 1
    TournamentBracketStage(
      bracketNumber: 1,
      title: 'VÒNG SƠ TUYỂN',
      roundName: 'Round of 32',
      opponentName: 'Hoàng Nam',
      opponentLevel: 2,
      opponentAvatarAsset: 'assets/images/ball_1.png',
      opponentCue: CueCatalog.standardCue,
      botDifficultyRating: 2,
      coinReward: 800,
      xpReward: 120,
      description: 'Trận khai màn gặp tay cơ nghiệp dư nổi bật khu vực.',
    ),

    // Bracket 2
    TournamentBracketStage(
      bracketNumber: 2,
      title: 'VÒNG TUYỂN CHỌN',
      roundName: 'Round of 16',
      opponentName: 'Minh Tuấn',
      opponentLevel: 4,
      opponentAvatarAsset: 'assets/images/ball_2.png',
      opponentCue: CueCatalog.titanStriker,
      botDifficultyRating: 4,
      coinReward: 1500,
      xpReward: 250,
      description: 'So tài cùng cơ thủ có lối đánh phòng thủ chặt chẽ.',
    ),

    // Bracket 3
    TournamentBracketStage(
      bracketNumber: 3,
      title: 'VÒNG TỨ KẾT',
      roundName: 'Quarter-Finals',
      opponentName: 'Kim Sơn',
      opponentLevel: 6,
      opponentAvatarAsset: 'assets/images/ball_3.png',
      opponentCue: CueCatalog.frostbite,
      botDifficultyRating: 6,
      coinReward: 3000,
      xpReward: 450,
      bonusMedalId: 'tournament_semis',
      description: 'Cuộc chiến bước vào Top 4 cơ thủ mạnh nhất giải.',
    ),

    // Bracket 4
    TournamentBracketStage(
      bracketNumber: 4,
      title: 'VÒNG BÁN KẾT',
      roundName: 'Semi-Finals',
      opponentName: 'Vincent Chen',
      opponentLevel: 9,
      opponentAvatarAsset: 'assets/images/ball_4.png',
      opponentCue: CueCatalog.goldenBull,
      botDifficultyRating: 8,
      coinReward: 5500,
      xpReward: 800,
      bonusMedalId: 'tournament_semis',
      description: 'Đối đầu bậc thầy gậy neon với kỹ năng dọn bàn thần tốc.',
    ),

    // Bracket 5: Grand Championship Finals
    TournamentBracketStage(
      bracketNumber: 5,
      title: 'ĐẠI CHUNG KẾT ĐỈNH PHONG',
      roundName: 'Grand Championship Finals',
      opponentName: 'Long Hoàng Vũ (Đương Kim Vô Địch)',
      opponentLevel: 16,
      opponentAvatarAsset: 'assets/images/ball_8.png',
      opponentCue: CueCatalog.dragonGod,
      botDifficultyRating: 10,
      coinReward: 15000,
      xpReward: 2500,
      bonusMedalId: 'tournament_champion',
      description: 'Trận thư hùng vĩ đại tranh chiếc Cúp Quán Quân danh giá tối thượng!',
    ),
  ];

  static TournamentBracketStage getByBracket(int bracket) {
    return brackets.firstWhere(
      (b) => b.bracketNumber == bracket,
      orElse: () => brackets.first,
    );
  }
}
